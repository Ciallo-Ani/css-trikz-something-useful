#include <sourcemod>
#include <sdkhooks>
#include <trikz>
#include <shavit>
#include <morecolors>

#pragma semicolon 1
#pragma newdecls required

bool gB_hide[MAXPLAYERS +1];

public Plugin myinfo = 
{
	name = "Player collision for trikz solidity",
	author = "Smesh, Ciallo",
	description = "Make able to collide only with 'teammate', Code improved by Ciallo",
	version = "0.2",
	url = ""
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_hide", RCM_hide, "Toggle hide");

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			OnClientPutInServer(i);
		}
	}
}

public void OnClientPutInServer(int client)
{
	if(!IsFakeClient(client))
	{
		gB_hide[client] = true;
		SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmitHide);
	}
}

public Action RCM_hide(int client, int args)
{
	gB_hide[client] = !gB_hide[client];

	if(gB_hide[client])
	{
		CPrintToChat(client, "{white}The players are now hidden.");
	}

	else
	{
		CPrintToChat(client, "{white}The players are now visible.");
	}

	return Plugin_Handled;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(IsValidEntity(entity) && StrContains(classname, "_projectile") != -1)
	{
		SDKHook(entity, SDKHook_SetTransmit, Hook_SetTransmitHideNade);
	}
}

public Action Hook_SetTransmitHide(int entity, int client) //entity - me, client - loop all clients
{
	if((client != entity) && (0 < entity <= MaxClients) && gB_hide[client] && IsPlayerAlive(client))
	{
		if(Shavit_GetClientTrack(entity) != Track_Solobonus)
		{
			if(Trikz_FindPartner(entity) == client) //make visible partner
			{
				return Plugin_Continue;
			}
			
			if((Trikz_FindPartner(entity) == -1) && (Trikz_FindPartner(client) == -1)) //make visible no mates for no mate
			{
				return Plugin_Continue;
			}

			return Plugin_Handled;
		}
		
		else //make invisible all players
		{
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

public Action Hook_SetTransmitHideNade(int entity, int client) //entity - nade, client - loop all clients
{	
	int iEntOwner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	int iPartner = Trikz_FindPartner(iEntOwner);

	if(gB_hide[client] && IsPlayerAlive(client))
	{
		if(iEntOwner == client) //make visible own nade
		{
			return Plugin_Continue;
		}

		if(iPartner == client) //make visible partner
		{
			return Plugin_Continue;
		}

		if((iPartner == -1) && (Trikz_FindPartner(client) == -1)) //make visible nade only for no mates
		{
			return Plugin_Continue;
		}

		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action Trikz_CheckSolidity(int ent1, int ent2)
{
	if(IsValidClient(ent1) && IsValidClient(ent2) && IsFakeClient(ent1) && IsFakeClient(ent2))//make bot no colide
	{
		return Plugin_Handled;
	}

	char sClassname_ent1[32];
	char sClassname_ent2[32];
	GetEntityClassname(ent1, sClassname_ent1, 32);
	GetEntityClassname(ent2, sClassname_ent2, 32);

	if(GetEntProp(ent1, Prop_Data, "m_CollisionGroup") == 2 || GetEntProp(ent2, Prop_Data, "m_CollisionGroup") == 2)//make client no colide if client is ghost.
	{
		if((IsValidClient(ent1) && IsValidClient(ent2)) || StrContains(sClassname_ent1, "projectile") != -1 || StrContains(sClassname_ent2, "projectile") != -1)
		{
			return Plugin_Handled;
		}
	}

	if(IsValidClient(ent1) && IsValidClient(ent2))//detect client
	{
		if(Trikz_FindPartner(ent1) != Trikz_FindPartner(Trikz_FindPartner(ent2)) && 
		Trikz_FindPartner(ent2) != Trikz_FindPartner(Trikz_FindPartner(ent1)))//make client no colide if partner is not mate.
		{
			return Plugin_Handled;
		}
	}

	if(StrContains(sClassname_ent1, "projectile") != -1 || StrContains(sClassname_ent2, "projectile") != -1)//detect nade
	{
		int iEntOwner;

		if(StrContains(sClassname_ent1, "projectile") != -1)
		{
			iEntOwner = GetEntPropEnt(ent1, Prop_Send, "m_hOwnerEntity");

			if(IsValidClient(iEntOwner) && Trikz_FindPartner(iEntOwner) != Trikz_FindPartner(Trikz_FindPartner(ent2)) && 
			IsValidClient(ent2) && Trikz_FindPartner(ent2) != Trikz_FindPartner(Trikz_FindPartner(iEntOwner)))//make client no nade colide if partner is not mate.
			{
				return Plugin_Handled;
			}
		}

		else if(StrContains(sClassname_ent2, "projectile") != -1)
		{
			iEntOwner = GetEntPropEnt(ent2, Prop_Send, "m_hOwnerEntity");

			if(IsValidClient(ent1) && Trikz_FindPartner(ent1) != Trikz_FindPartner(Trikz_FindPartner(iEntOwner)) && 
			IsValidClient(iEntOwner) && Trikz_FindPartner(iEntOwner) != Trikz_FindPartner(Trikz_FindPartner(ent1)))//make client no nade colide if partner is not mate.
			{
				return Plugin_Handled;
			}
		}

		if(StrContains(sClassname_ent1, "projectile") != -1 && StrContains(sClassname_ent2, "projectile") != -1)
		{
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}