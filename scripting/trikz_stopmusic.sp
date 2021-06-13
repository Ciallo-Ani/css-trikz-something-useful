#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <dhooks>
#include <shavit>

bool gB_Stopmusic[MAXPLAYERS+1];

public void OnPluginStart()
{
	RegConsoleCmd("sm_music", Command_Stopmusic);

	Handle hGameData = LoadGameConfigFile("soundscapeupdate.games");
	if(!hGameData)
	{
		SetFailState("Failed to load soundscapeupdate gamedata.");
	}
	
	Handle hSoundscapeUpdate = DHookCreateDetour(Address_Null, CallConv_THISCALL, ReturnType_Void, ThisPointer_CBaseEntity);
	
	if(!hSoundscapeUpdate)
	{
		delete hGameData;
		delete hSoundscapeUpdate;
		SetFailState("Failed to setup detour for CEnvSoundscape__UpdateForPlayer");
	}
	
	if(!DHookSetFromConf(hSoundscapeUpdate, hGameData, SDKConf_Signature, "CEnvSoundscape::UpdateForPlayer"))
    {
		delete hGameData;
		delete hSoundscapeUpdate;
		SetFailState("Failed to signature for CEnvSoundscape__UpdateForPlayer from gamedata.");
	}
	
	DHookAddParam(hSoundscapeUpdate, HookParamType_Object, 32, DHookPass_ByRef|DHookPass_ODTOR|DHookPass_OASSIGNOP);
	
	if(!DHookEnableDetour(hSoundscapeUpdate, false, SoundscapeUpdateForPlayer))
	{
		delete hGameData;
		delete hSoundscapeUpdate;
		SetFailState("Failed to detour CEnvSoundscape__UpdateForPlayer.");
	}
	
	delete hGameData;
	delete hSoundscapeUpdate;
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			OnClientPutInServer(i);
		}
	}
}

public MRESReturn SoundscapeUpdateForPlayer(int pThis, Handle hParams)
{
	int client = DHookGetParamObjectPtrVar(hParams, 1, 0, ObjectValueType_CBaseEntityPtr);

	if(!IsValidEntity(pThis) || !IsValidEdict(pThis))
	{
		return MRES_Ignored;
	}

	char sScape[64];

	GetEdictClassname(pThis, sScape, sizeof(sScape));

	if(!StrEqual(sScape,"env_soundscape") && !StrEqual(sScape,"env_soundscape_triggerable") && !StrEqual(sScape,"env_soundscape_proxy"))
	{
		return MRES_Ignored;
	}

	if(0 < client <= MaxClients)
	{
		if(gB_Stopmusic[client])
		{
			DHookSetParamObjectPtrVar(hParams, 1, 28, ObjectValueType_Bool, false); //bInRange
			return MRES_Supercede;
		}

		return MRES_Handled;
	}

	return MRES_Ignored;
}

public void OnClientPutInServer(int client)
{
	if(IsValidClient(client))
	{
		gB_Stopmusic[client] = true;
	}
}

public Action Command_Stopmusic(int client, int args)
{
	gB_Stopmusic[client] = !gB_Stopmusic[client];

	if(gB_Stopmusic[client])
	{
		Shavit_PrintToChat(client, "静态音乐：已关闭 (需要等到音乐结束或控制台stopsound)");
	}

	else
	{
		Shavit_PrintToChat(client, "静态音乐：已开启");
	}

	return Plugin_Handled;
}