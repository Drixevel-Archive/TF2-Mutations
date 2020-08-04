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
#include <misc-colors>

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
		this.index = -1;
		this.active = false;
		this.plugin = null;
		this.start = null;
		this.end = null;
	}

	void Add(const char[] name, Handle plugin, Function func_start, Function func_end)
	{
		strcopy(this.name, 64, name);
		this.index = g_TotalMutations;
		this.plugin = plugin;

		this.start = new PrivateForward(ET_Ignore);
		this.start.AddFunction(plugin, func_start);

		this.end = new PrivateForward(ET_Ignore);
		this.end.AddFunction(plugin, func_end);
	}

	void Fire(const char[] name)
	{
		if (this.plugin == null || !this.active)
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
	return g_Mutations[GetNativeCell(1)].active;
}

public void Event_OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	char sMutations[64];
	for (int i = 0; i < g_TotalMutations; i++)
	{
		g_Mutations[i].active = view_as<bool>(GetRandomInt(0, 1));
		
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