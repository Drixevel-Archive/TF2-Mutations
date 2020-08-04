/*****************************/
//Pragma
#pragma semicolon 1
#pragma newdecls required

/*****************************/
//Defines
#define PLUGIN_NAME "[TF2] Mutation - Glows"
#define PLUGIN_DESCRIPTION "A random mutation which adds glows to all players."
#define PLUGIN_VERSION "1.0.0"

/*****************************/
//Includes
#include <sourcemod>
#include <tf2_stocks>
#include <tf2-mutations>

#include <tf2attributes>

/*****************************/
//ConVars

/*****************************/
//Globals

int assigned_mutation = NO_MUTATION;
int g_Glow[MAXPLAYERS + 1] = {INVALID_ENT_REFERENCE, ...};

int color_red[4] = {255, 0, 0, 255};
int color_blue[4] = {0, 0, 255, 255};

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
	HookEvent("player_death", Event_OnPlayerDeath);
}

public void OnPluginEnd()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;

		if (IsValidEntity(g_Glow[i]))
			AcceptEntityInput(g_Glow[i], "Kill");
	}
}

public void TF2_AddMutations()
{
	assigned_mutation = TF2_AddMutation("Glows", OnMutationStart, OnMutationEnd);
}

public void OnMutationStart(int mutation)
{
	char targetname[64];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		if (IsValidEntity(g_Glow[i]))
			AcceptEntityInput(g_Glow[i], "Kill");
		
		FormatEx(targetname, sizeof(targetname), "glow_%i", i);
		g_Glow[i] = EntIndexToEntRef(TF2_CreateGlow(targetname, i, GetClientTeam(i) == 2 ? color_red : color_blue));
	}
}

public void OnMutationEnd(int mutation)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;

		if (IsValidEntity(g_Glow[i]))
			AcceptEntityInput(g_Glow[i], "Kill");
	}
}

public void Event_OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client) && TF2_IsMutationActive(assigned_mutation))
	{
		if (IsValidEntity(g_Glow[client]))
			AcceptEntityInput(g_Glow[client], "Kill");
		
		char targetname[64];
		FormatEx(targetname, sizeof(targetname), "glow_%i", client);
		
		g_Glow[client] = EntIndexToEntRef(TF2_CreateGlow(targetname, client, GetClientTeam(client) == 2 ? color_red : color_blue));
	}
}

public void Event_OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client) && TF2_IsMutationActive(assigned_mutation))
	{
		if (IsValidEntity(g_Glow[client]))
			AcceptEntityInput(g_Glow[client], "Kill");
	}
}

public void OnClientDisconnect(int client)
{
	if (IsValidEntity(g_Glow[client]))
		AcceptEntityInput(g_Glow[client], "Kill");
}

public void OnClientDisconnect_Post(int client)
{
	g_Glow[client] = INVALID_ENT_REFERENCE;
}

stock int TF2_CreateGlow(const char[] name, int target, int color[4] = {255, 255, 255, 255})
{
	char sClassname[64];
	GetEntityClassname(target, sClassname, sizeof(sClassname));

	char sTarget[128];
	Format(sTarget, sizeof(sTarget), "%s%i", sClassname, target);
	DispatchKeyValue(target, "targetname", sTarget);

	int glow = CreateEntityByName("tf_glow");

	if (IsValidEntity(glow))
	{
		char sGlow[64];
		Format(sGlow, sizeof(sGlow), "%i %i %i %i", color[0], color[1], color[2], color[3]);

		DispatchKeyValue(glow, "targetname", name);
		DispatchKeyValue(glow, "target", sTarget);
		DispatchKeyValue(glow, "Mode", "1"); //Mode is currently broken.
		DispatchKeyValue(glow, "GlowColor", sGlow);
		DispatchSpawn(glow);
		
		SetVariantString("!activator");
		AcceptEntityInput(glow, "SetParent", target, glow);

		AcceptEntityInput(glow, "Enable");
	}

	return glow;
}