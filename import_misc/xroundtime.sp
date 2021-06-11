#pragma semicolon 1
#pragma newdecls required

//https://hlmod.ru/threads/kak-uvelichit-vremja-raunda.25163/#post-209976
//https://forums.alliedmods.net/showpost.php?p=1179098&postcount=4
public void OnPluginStart()
{
	SetConVarBounds(FindConVar("mp_roundtime"), ConVarBound_Lower, true, 0.0);
}