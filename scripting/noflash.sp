#include <dhooks>
#include <sourcemod>

DynamicDetour gH_Noflash = null;

ConVar gCV_DelayFlashTime = null;

public void OnPluginStart()
{
	gCV_DelayFlashTime = CreateConVar("sv_delayflash", "0.0", "延长闪光消失时间. 0为不变，值必须大于等于0.", 0, true, 0.0, false);

	GameData gamedata = new GameData("noflash.games");

	if (gamedata == null)
	{
		SetFailState("Failed to load noflash gamedata");
	}

	if (!(gH_Noflash = DHookCreateDetour(Address_Null, CallConv_THISCALL, ReturnType_Void, ThisPointer_CBaseEntity)))
	{
		SetFailState("Failed to create detour for CFlashbangProjectile::Detonate");
	}

	if (!DHookSetFromConf(gH_Noflash, gamedata, SDKConf_Signature, "CFlashbangProjectile::Detonate"))
	{
		SetFailState("Failed to get address for CFlashbangProjectile::Detonate");
	}

	gH_Noflash.Enable(Hook_Pre, Detour_OnFlashbangDetonate);
}

public MRESReturn Detour_OnFlashbangDetonate(int pThis)
{
	if(gCV_DelayFlashTime.FloatValue > 0.0)
	{
		CreateTimer(gCV_DelayFlashTime.FloatValue, Timer_KillFlash, pThis);
	}
	else
	{
		AcceptEntityInput(pThis, "kill");
	}
	
	return MRES_Supercede;
}

public Action Timer_KillFlash(Handle timer, any data)
{
    AcceptEntityInput(data, "kill");
}