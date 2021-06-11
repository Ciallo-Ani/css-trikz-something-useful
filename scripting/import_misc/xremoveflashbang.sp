#include <sdktools>
#include <dhooks>

public Plugin myinfo =
{
	name = "Remove the flashbang on detoante",
	author = "Smesh, thanks to https://forums.alliedmods.net/showthread.php?t=159876 (Dr!fter), thanks to george",
	description = "Remove the flashabang on detonate.",
	version = "26.02.2021",
	url = "https://www.sourcemod.net/"
}

public void OnPluginStart()
{
	Handle hGamedata = LoadGameConfigFile("fbdetonate.games")
	if(!hGamedata)
	{
		SetFailState("Failed to load fbtools.games!")
		delete hGamedata
	}
	Handle hFunctions = DHookCreateFromConf(hGamedata, "CFlashbangProjectile__Detonate")
	if(!hFunctions)
	{
		delete hGamedata
		delete hFunctions
		SetFailState("Failed to setup detour for FlashbangProjectile__Detonate")
	}
	if(!DHookEnableDetour(hFunctions, false, OnFlashDetonate))
	{
		delete hGamedata;
		delete hFunctions;
		SetFailState("Failed to detour CFlashbangProjectile__Detonate.");
	}
	delete hGamedata
	delete hFunctions //the Functions section is now cached which is all we need for the next bit.
}

MRESReturn OnFlashDetonate(int pThis, Handle hReturn)
{
	if(IsValidEntity(pThis))
	{
		AcceptEntityInput(pThis, "Kill")
		return MRES_Supercede
	}
	return MRES_Ignored
}