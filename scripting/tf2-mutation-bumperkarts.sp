/*****************************/
//Pragma
#pragma semicolon 1
#pragma newdecls required

/*****************************/
//Defines
#define PLUGIN_NAME "[TF2] Mutation - Bumper Karts"
#define PLUGIN_DESCRIPTION "A random mutation which forces all players into Bumper Karts."
#define PLUGIN_VERSION "1.0.0"

/*****************************/
//Includes
#include <sourcemod>
#include <tf2_stocks>
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
	assigned_mutation = TF2_AddMutation("Bumper Karts", OnMutationStart, OnMutationEnd);
}

public void OnMutationStart(int mutation)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		TF2_AddCondition(i, TFCond_HalloweenKart, TFCondDuration_Infinite);
	}
}

public void OnMutationEnd(int mutation)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		TF2_RemoveCondition(i, TFCond_HalloweenKart);
	}
}

public void Event_OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client) && TF2_IsMutationActive(assigned_mutation))
	{
		TF2_AddCondition(client, TFCond_HalloweenKart, TFCondDuration_Infinite);
	}
}

public Action OnClientCommand(int client, int args)
{
	char sCommand[32];
	GetCmdArgString(sCommand, sizeof(sCommand));

	if (StrEqual(sCommand, "kill", false) || StrEqual(sCommand, "explode", false))
	{
		TF2_RemoveCondition(client, TFCond_HalloweenKart);
	}

	return Plugin_Continue;
}