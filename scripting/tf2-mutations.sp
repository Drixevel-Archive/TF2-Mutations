/*****************************/
//Pragma
#pragma semicolon 1
#pragma newdecls required

/*****************************/
//Defines
#define PLUGIN_NAME "[TF2] Mutations"
#define PLUGIN_DESCRIPTION "Random gameplay elements each match for Team Fortress 2."
#define PLUGIN_VERSION "1.0.0"

#define MAX_MUTATIONS 256

/*****************************/
//Includes
#include <sourcemod>
#include <sdktools>
#include <misc-colors>
#include <tf2-mutations>

/*****************************/
//ConVars

/*****************************/
//Globals

int g_TotalMutations;

enum struct Mutations
{
	char name[64];
	int index;

	bool active;

	Handle plugin;

	PrivateForward start;
	PrivateForward end;

	void Init()
	{
		this.name[0] = '\0';
		this.index = NO_MUTATION;
		this.active = false;
		this.plugin = null;
		this.start = null;
		this.end = null;
	}

	void Clear()
	{
		this.name[0] = '\0';
		this.index = NO_MUTATION;
		this.active = false;

		delete this.start;
		delete this.end;
	}

	void Add(const char[] name, Handle plugin, Function func_start, Function func_end)
	{
		strcopy(this.name, 64, name);
		this.index = g_TotalMutations;
		this.plugin = plugin;

		this.start = new PrivateForward(ET_Ignore, Param_Cell);
		this.start.AddFunction(plugin, func_start);

		this.end = new PrivateForward(ET_Ignore, Param_Cell);
		this.end.AddFunction(plugin, func_end);
	}

	void Fire(const char[] name)
	{
		if (this.plugin == null)
			return;
		
		if (StrEqual(name, "start", false) && this.start != null && this.start && GetForwardFunctionCount(this.start) > 0)
		{
			Call_StartForward(this.start);
			Call_PushCell(this.index);
			Call_Finish();
		}
		else if (StrEqual(name, "end", false) && this.end != null && this.end && GetForwardFunctionCount(this.end) > 0)
		{
			Call_StartForward(this.end);
			Call_PushCell(this.index);
			Call_Finish();
		}
	}
}

Mutations g_Mutations[MAX_MUTATIONS];

Handle g_Forward_AddMutations;

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

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("tf2-mutations");

	CreateNative("TF2_AddMutation", Native_AddMutation);
	CreateNative("TF2_IsMutationActive", Native_IsMutationActive);

	g_Forward_AddMutations = CreateGlobalForward("TF2_AddMutations", ET_Ignore);

	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	//Make sure the data's consistent.
	for (int i = 0; i < MAX_MUTATIONS; i++)
		g_Mutations[i].Init();
	
	HookEvent("teamplay_round_start", Event_OnRoundStart);
	HookEvent("teamplay_round_win", Event_OnRoundEnd);

	RegAdminCmd("sm_mutations", Command_Mutations, ADMFLAG_GENERIC);
	RegAdminCmd("sm_syncmutations", Command_SyncMutations, ADMFLAG_GENERIC);
}

public void OnAllPluginsLoaded()
{
	//Called here since all of the mutation plugins will be active.
	Call_StartForward(g_Forward_AddMutations);
	Call_Finish();
}

public int Native_AddMutation(Handle plugin, int numParams)
{
	int size;
	GetNativeStringLength(1, size); size++;
	
	char[] name = new char[size];
	GetNativeString(1, name, size);

	g_Mutations[g_TotalMutations].Add(name, plugin, GetNativeFunction(2), GetNativeFunction(3));

	int index = g_TotalMutations;
	g_TotalMutations++;
	
	return index;
}

public int Native_IsMutationActive(Handle plugin, int numParams)
{
	int mutation = GetNativeCell(1);

	if (mutation < 0 || mutation > MAX_MUTATIONS)
		return false;

	return g_Mutations[GetNativeCell(1)].active;
}

public void Event_OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (GameRules_GetProp("m_bInWaitingForPlayers") || GetRandomFloat(0.0, 100.0) > 50.0)
		return;
	
	char sMutations[64];
	for (int i = 0; i < g_TotalMutations; i++)
	{
		g_Mutations[i].active = view_as<bool>(GetRandomFloat(0.0, 100.0) <= 25.0);
		
		if (g_Mutations[i].active)
			Format(sMutations, sizeof(sMutations), "%s%s%s", sMutations, strlen(sMutations) == 0 ? " " : ", ", g_Mutations[i].name);
	}

	CPrintToChatAll("{crimson}[{fullred}Mutations{crimson}] {beige}Active:{chartreuse}%s", strlen(sMutations) > 0 ? sMutations : " None Active");

	for (int i = 0; i < g_TotalMutations; i++)
		g_Mutations[i].Fire("start");
}

public void Event_OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 0; i < g_TotalMutations; i++)
		g_Mutations[i].Fire("end");
}

public Action Command_Mutations(int client, int args)
{
	OpenMutationsMenu(client);
	return Plugin_Handled;
}

void OpenMutationsMenu(int client)
{
	Menu menu = new Menu(MenuHandler_Mutations);
	menu.SetTitle("Available Mutations:");

	char sID[16]; char sDisplay[256];
	for (int i = 0; i < g_TotalMutations; i++)
	{
		IntToString(i, sID, sizeof(sID));
		Format(sDisplay, sizeof(sDisplay), "[%s] %s", g_Mutations[i].active ? "X" : "", g_Mutations[i].name);
		menu.AddItem(sID, sDisplay);
	}

	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_Mutations(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sID[16];
			menu.GetItem(param2, sID, sizeof(sID));
			int mutation = StringToInt(sID);

			g_Mutations[mutation].active = !g_Mutations[mutation].active;

			if (g_Mutations[mutation].active)
			{
				g_Mutations[mutation].Fire("start");
				CPrintToChatAll("{crimson}[{fullred}Mutations{crimson}] {beige}Enabled: {chartreuse}%s", g_Mutations[mutation].name);
			}
			else
			{
				g_Mutations[mutation].Fire("end");
				CPrintToChatAll("{crimson}[{fullred}Mutations{crimson}] {beige}Disabled: {chartreuse}%s", g_Mutations[mutation].name);
			}

			OpenMutationsMenu(param1);
		}
		case MenuAction_End:
			delete menu;
	}
}

public Action Command_SyncMutations(int client, int args)
{
	for (int i = 0; i < MAX_MUTATIONS; i++)
		g_Mutations[i].Clear();
	g_TotalMutations = 0;
	
	OnAllPluginsLoaded();
	CPrintToChat(client, "{crimson}[{fullred}Mutations{crimson}] {beige}Mutations have been synced.");
	return Plugin_Handled;
}