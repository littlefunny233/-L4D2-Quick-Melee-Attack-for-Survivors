#include <sourcemod>
#include <sdktools>

bool Gived[MAXPLAYERS+1] = {false};
char Weaponname[MAXPLAYERS+1][256];
int Chainsaw_index[MAXPLAYERS+1];

int Pistol_clip[MAXPLAYERS+1];

Do_SpawnItem(client, const String:type[]) {
	StripAndExecuteClientCommand(client, "give", type);
}

StripAndExecuteClientCommand(client, const String:command[], const String:arguments[]) {
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
}

public bool IsPlayerFalling(int client)
{
	return GetEntProp(client, Prop_Send, "m_isHangingFromLedge") != 0;
}
public bool IsPlayerFallen(int client)
{
	return GetEntProp(client, Prop_Send, "m_isIncapacitated") != 0;
}
public bool IsPlayerAlright(int client)
{
	return !(IsPlayerFalling(client) || IsPlayerFallen(client));
}


public void return_pistol(int client)
{
	if(Gived[client] == true)
	{
		RemovePlayerItem(client, Chainsaw_index[client]);
		Do_SpawnItem(client, Weaponname[client]);
		int slot2 = GetPlayerWeaponSlot(client, 1);
		if(StrContains(Weaponname[client], "pistol") > -1)
		{
			if(StrContains(Weaponname[client], "pistol_magnum") == -1)
			{
				SetEntProp(slot2, Prop_Send, "m_hasDualWeapons", 1);
			}
			SetEntProp(slot2, Prop_Send, "m_iClip1", Pistol_clip[client]);
		}
		Gived[client] = false;
	}
}

public void quick_melee(int client)
{
	if(Gived[client] == false)
	{
		int slot2 = GetPlayerWeaponSlot(client, 1);
		GetEdictClassname(slot2, Weaponname[client], 256);
		if(StrContains(Weaponname[client], "melee") > -1)
		{
			return;
		}
		if(StrContains(Weaponname[client], "chainsaw") > -1)
		{
			return;
		}
		if(StrContains(Weaponname[client], "pistol") > -1)
		{
			Pistol_clip[client] = GetEntProp(slot2, Prop_Data, "m_iClip1");
		}
		RemovePlayerItem(client, slot2);
		Do_SpawnItem(client, "fireaxe");
		Chainsaw_index[client] = GetPlayerWeaponSlot(client, 1);
		Gived[client] = true;
	}
}

public void drop_melee(int client)
{
	if(Gived[client] == false)
	{
		int slot2 = GetPlayerWeaponSlot(client, 1);
		GetEdictClassname(slot2, Weaponname[client], 256);
		if((StrContains(Weaponname[client], "melee") > -1) || StrContains(Weaponname[client], "chainsaw") > -1)
		{
			RemovePlayerItem(client, slot2);
			Do_SpawnItem(client, "pistol");
		}
	}
}

public void OnGameFrame()
{
    for(int client = 1; client <= MaxClients; client++)
    {
        if(IsValidEntity(client))
        {
            if(client && !IsFakeClient(client) && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && IsPlayerAlright(client))
            {
				int buttons = GetClientButtons(client);
				if(buttons & IN_SPEED)
				{
					drop_melee(client);
				}
				if(buttons & IN_ZOOM)
				{
					quick_melee(client);
				}
				else
				{
					return_pistol(client);
				}
            }
        }
    }
}

public void ResetAll()
{
	for(int client = 1; client <= MaxClients; client++)
	{
		Gived[client] = false;
	}
}

public void Evnet_round(Event event, const char[] name, bool dontBroadcast)
{
	ResetAll();
}

public void Event_replace(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "player"));
    if(client && IsClientInGame(client) && GetClientTeam(client) == 2)
    {
		Gived[client] = false;
    }
	int client2 = GetClientOfUserId(GetEventInt(event, "bot"));
    if(client2 && IsClientInGame(client2) && GetClientTeam(client2) == 2)
    {
		Gived[client2] = false;
    }
}

public Event_death(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(client && IsClientInGame(client) && GetClientTeam(client) == 2)
    {
		Gived[client] = false;
    }
}

public Event_team(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(client && IsClientInGame(client))
    {
		Gived[client] = false;
    }
}

public void OnPluginStart()
{
	HookEvent("player_bot_replace", Event_replace);
    HookEvent("bot_player_replace", Event_replace);
	HookEvent("player_death", Event_death);
	HookEvent("player_team", Event_team);
    HookEvent("round_start", Evnet_round);
}