#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name        = "boost-fix",
	author      = "Tengu, Smesh",
	description = "<insert_description_here>",
	version     = "0.2",
	url         = "http://steamcommunity.com/id/tengulawl/"
}

int gI_boost[MAXPLAYERS + 1];
int gI_flash[MAXPLAYERS + 1];
int gI_playerFlags[MAXPLAYERS + 1];
int gI_skyFrame[MAXPLAYERS + 1];
int gI_skyStep[MAXPLAYERS + 1];
float gF_boostTime[MAXPLAYERS + 1];
float gF_fallVelBooster[MAXPLAYERS + 1][3];
float gF_fallVel[MAXPLAYERS + 1][3];
float gF_vecVelBoostFix[MAXPLAYERS + 1][3];
bool gB_bouncedOff[2048 + 1];
bool gB_groundBoost[MAXPLAYERS + 1];

public void OnMapStart()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			OnClientPutInServer(i);
		}
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_StartTouch, StartTouch_SkyFix);
	SDKHook(client, SDKHook_PostThinkPost, PostThinkPost_BoostFix);
}

public void OnClientDisconnect(int client)
{
	gI_skyFrame[client] = 0;
	gI_skyStep[client] = 0;
	gF_boostTime[client] = 0.0;
	gI_playerFlags[client] = 0;
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	gI_playerFlags[client] = GetEntityFlags(client);

	if(gI_boost[client] == 10)
	{
		gI_boost[client] = 0;
	}

	if(gI_boost[client] == 15)
	{
		for(int i = 0; i <= 2; i++)
		{
			gF_vecVelBoostFix[client][i] = 0.0;
		}

		gI_boost[client] = 0;
		gI_skyStep[client] = 0;
	}

	if(7 >= gI_boost[client] >= 1 && EntRefToEntIndex(gI_flash[client]) != INVALID_ENT_REFERENCE)
	{
		gI_skyStep[client] = 0;
	}

	if(gI_boost[client] == 8 && EntRefToEntIndex(gI_flash[client]) != INVALID_ENT_REFERENCE)
	{
		for(int i = 0; i <= 2; i++)
		{
			gF_vecVelBoostFix[client][i] = 0.0;
		}

		gI_boost[client] = 0;
		gI_skyStep[client] = 0;
	}

	if(1 <= gI_skyFrame[client] <= 5)
	{
		gI_skyFrame[client]++;
	}

	if(gI_skyFrame[client] >= 5)
	{
		gI_skyFrame[client] = 0;
		gI_skyStep[client] = 0;
	}

	if(gI_boost[client] && gI_skyStep[client])
	{
		gI_skyFrame[client] = 0;
		gI_skyStep[client] = 0;
	}

	if(gI_skyStep[client] == 1 && GetEntityFlags(client) & FL_ONGROUND && GetGameTime() - gF_boostTime[client] > 0.15)
	{
		gF_fallVelBooster[client][2] = gF_fallVelBooster[client][2] * 3.5;
		gF_fallVel[client][2] = gF_fallVelBooster[client][2];

		if(gF_fallVelBooster[client][2] > 800.0)
		{
			gF_fallVel[client][2] = 800.0;
		}

		if(buttons & IN_JUMP)
		{
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, gF_fallVel[client]);

			gI_skyStep[client] = 0;
			gF_fallVel[client][2] = 0.0;
			gI_skyFrame[client] = 0;
		}
	}

	return Plugin_Continue;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(StrEqual(classname, "flashbang_projectile"))
	{
		gB_bouncedOff[entity] = false;
		
		SDKHook(entity, SDKHook_StartTouch, StartTouch_OnProjectileBoostFix);
		SDKHook(entity, SDKHook_EndTouch, EndTouch_OnProjectileBoostFix);
	}
}

public Action StartTouch_OnProjectileBoostFix(int entity, int other)
{
	if(!IsValidClient(other))
	{
		return Plugin_Continue;
	}

	CreateTimer(0.25, Timer_RemoveEntity, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);

	if(gI_boost[other] || gI_playerFlags[other] & FL_ONGROUND)
	{
		return Plugin_Continue;
	}

	float vecOriginOther[3];
	GetClientAbsOrigin(other, vecOriginOther);

	float vecOriginEntity[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vecOriginEntity);

	if(vecOriginOther[2] >= vecOriginEntity[2])
	{
		float vecVelClient[3];
		GetEntPropVector(other, Prop_Data, "m_vecAbsVelocity", vecVelClient);

		float vecVelEntity[3];
		GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", vecVelEntity);

		gI_boost[other] = 1;

		vecVelClient[0] -= vecVelEntity[0] * 0.9964619;
		vecVelClient[1] -= vecVelEntity[1] * 0.9964619;

		gF_vecVelBoostFix[other][0] = vecVelClient[0];
		gF_vecVelBoostFix[other][1] = vecVelClient[1];
		gF_vecVelBoostFix[other][2] = FloatAbs(vecVelEntity[2]);

		gF_boostTime[other] = GetGameTime();
		gB_groundBoost[other] = gB_bouncedOff[entity];
		SetEntProp(entity, Prop_Send, "m_nSolidType", 0); //https://forums.alliedmods.net/showthread.php?t=286568 non model no solid model Gray83 author of solid model types.
		gI_flash[other] = EntIndexToEntRef(entity); //check this for postthink post to correct set first telelportentity speed. starttouch have some outputs only one of them is coorect wich gives correct other(player) id.
	}

	return Plugin_Continue;
}

public Action EndTouch_OnProjectileBoostFix(int entity, int other)
{
	if(!other)
	{
		gB_bouncedOff[entity] = true; //get from tengu github tengulawl scriptig boost-fix.sp
	}
}

public Action Timer_RemoveEntity(Handle timer, any entref)
{
	int entity = EntRefToEntIndex(entref);

	if(entity != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(entity, "Kill");
	}
	
	return Plugin_Continue;
}

public void StartTouch_SkyFix(int client, int other) //client = booster; other = flyer
{
	if(!IsValidClient(other) || gI_playerFlags[other] & FL_ONGROUND || gI_boost[client] || GetGameTime() - gF_boostTime[client] < 0.15)
	{
		return;
	}
	
	float vecAbsBooster[3];
	GetEntPropVector(client, Prop_Data, "m_vecOrigin", vecAbsBooster);

	float vecAbsFlyer[3];
	GetEntPropVector(other, Prop_Data, "m_vecOrigin", vecAbsFlyer);

	float vecMaxs[3];
	GetEntPropVector(client, Prop_Data, "m_vecMaxs", vecMaxs);

	float delta = vecAbsFlyer[2] - vecAbsBooster[2] - vecMaxs[2]; //https://github.com/tengulawl/scripting/blob/master/boost-fix.sp#L71

	if(0.0 <= delta <= 2.0) //https://github.com/tengulawl/scripting/blob/master/boost-fix.sp#L75
	{
		if(!(GetEntityFlags(client) & FL_ONGROUND) && gI_skyStep[other] == 0)// can duck sky
		{
			float vecVelBooster[3];
			GetEntPropVector(client, Prop_Data, "m_vecVelocity", vecVelBooster);
			gF_fallVelBooster[other][2] = vecVelBooster[2];

			if(vecVelBooster[2] > 0.0)
			{
				float vecVelFlyer[3];
				GetEntPropVector(other, Prop_Data, "m_vecVelocity", vecVelFlyer);

				gF_fallVel[other][0] = vecVelFlyer[0];
				gF_fallVel[other][1] = vecVelFlyer[1];
				gF_fallVel[other][2] = FloatAbs(vecVelFlyer[2]);

				gI_skyStep[other] = 1;
				gI_skyFrame[other] = 1;
			}
		}
	}
}

public void PostThinkPost_BoostFix(int client)
{
	if(gI_boost[client] == 1)
	{
		int entity = EntRefToEntIndex(gI_flash[client]);

		if(entity != INVALID_ENT_REFERENCE)
		{
			float vecVelEntity[3];
			GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", vecVelEntity);

			if(vecVelEntity[2] > 0.0)
			{
				vecVelEntity[0] = vecVelEntity[0] * 0.135;
				vecVelEntity[1] = vecVelEntity[1] * 0.135;
				vecVelEntity[2] = vecVelEntity[2] * -0.135;

				TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vecVelEntity);
			}
		}

		gI_boost[client] = 2;
		gI_skyStep[client] = 0;
	}

	if(gI_boost[client] == 2)
	{
		if(!gB_groundBoost[client])
		{
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, gF_vecVelBoostFix[client]);
		}

		else
		{
			gF_vecVelBoostFix[client][2] *= 3.0;
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, gF_vecVelBoostFix[client]);
		}

		gI_boost[client] = 0;
		gI_skyStep[client] = 0;
	}
}

bool IsValidClient(int client, bool alive = false)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && (!alive || IsPlayerAlive(client));
}