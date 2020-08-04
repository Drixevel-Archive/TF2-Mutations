/*****************************/
//Pragma
#pragma semicolon 1
#pragma newdecls required

/*****************************/
//Defines
#define PLUGIN_NAME "[TF2] Mutation - More Health"
#define PLUGIN_DESCRIPTION "A random mutation which gives all players more health."
#define PLUGIN_VERSION "1.0.0"

/*****************************/
//Includes
#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <tf2-mutations>

/*****************************/
//ConVars

/*****************************/
//Globals

int assigned_mutation = NO_MUTATION;

/*****************************/
//Plugin Info
public Plugin myinfo = 
{
	name = PLUGIN_NAME, 
	author = "Drixevel", 
	description = PLUGIN_DESCRIPTION, 
	version = PLUGIN_VERSION, 
	url = "https://drixevel.dev/"
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");

	HookEvent("player_spawn", Event_OnPlayerSpawn);
	HookEvent("player_changeclass", Event_OnPlayerSpawn);
}

public void TF2_AddMutations()
{
	assigned_mutation = TF2_AddMutation("More Health", OnMutationStart, OnMutationEnd);
}

public void OnMutationStart(int mutation)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		SetEntityHealth(i, TF2_GetMaxHealth(i) * 2);
		SDKHook(i, SDKHook_GetMaxHealth, OnGetMaxHealth);
	}
}

public Action OnGetMaxHealth(int entity, int& maxhealth)
{
	if (TF2_IsMutationActive(assigned_mutation))
	{
		maxhealth *= 2;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

public void OnMutationEnd(int mutation)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		SetEntityHealth(i, TF2_GetMaxHealth(i));
		SDKUnhook(i, SDKHook_GetMaxHealth, OnGetMaxHealth);
	}
}

public void Event_OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client) && TF2_IsMutationActive(assigned_mutation))
	{
		SetEntityHealth(client, TF2_GetMaxHealth(client) * 2);
	}
}

stock int TF2_GetMaxHealth(int client)
{
	int maxhealth = GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, client);
	return ((maxhealth == -1 || maxhealth == 80896) ? GetEntProp(client, Prop_Data, "m_iMaxHealth") : maxhealth);
}