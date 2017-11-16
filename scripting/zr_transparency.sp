#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <zombiereloaded>
	
#pragma newdecls required

#define PLUGIN_AUTHOR "Agent Wesker"
#define PLUGIN_VERSION "1.1"

//Bit Macros
#define SetBit(%1,%2)      (%1[%2>>5] |= (1<<(%2 & 31)))
#define ClearBit(%1,%2)    (%1[%2>>5] &= ~(1<<(%2 & 31)))
#define CheckBit(%1,%2)    (%1[%2>>5] & (1<<(%2 & 31)))

//Global Variables
ConVar g_ConVar_Distance; //Distance ConVar
ConVar g_ConVar_CheckDelay; //Check Delay ConVar
ConVar g_ConVar_UndoDelay; //Undo Delay ConVar
float g_fCheckTime[MAXPLAYERS+1]; //Player check time array
float g_fUndoTime[MAXPLAYERS+1]; //Player undo time array
float g_fDistance; //Distance ConVar
float g_fCheckDelay; //Check Delay ConVar
float g_fUndoDelay; //Undo Delay ConVar
int g_iTagged[(MAXPLAYERS >> 5) + 1]; //Bool array whether player is transparent or not
int g_iSkip[(MAXPLAYERS >> 5) + 1]; //Bool array whether player is zombie / invalid or not

public Plugin myinfo =  {
	name = "ZR Transparency",
	author = PLUGIN_AUTHOR,
	description = "Humans in close proximity become transparent",
	version = PLUGIN_VERSION,
	url = "https://steam-gamers.net"
};

public void OnPluginStart()
{	
	
	g_ConVar_Distance = CreateConVar("sm_transparency_distance", "200.0", "Distance within which the player is made transparent", 0, true, 0.0, true, 10000.0);
	g_fDistance = GetConVarFloat(g_ConVar_Distance);
	HookConVarChange(g_ConVar_Distance, OnConVarChanged);
	
	g_ConVar_CheckDelay = CreateConVar("sm_transparency_check", "0.5", "Time (in seconds) between checking opaque player distance", 0, true, 0.0, true, 30.0);
	g_fCheckDelay = GetConVarFloat(g_ConVar_CheckDelay);
	HookConVarChange(g_ConVar_CheckDelay, OnConVarChanged);
	
	g_ConVar_UndoDelay = CreateConVar("sm_transparency_undo", "2.0", "Time (in seconds) between checking transparent player distance", 0, true, 0.0, true, 50.0);
	g_fUndoDelay = GetConVarFloat(g_ConVar_UndoDelay);
	HookConVarChange(g_ConVar_UndoDelay, OnConVarChanged);
	
	HookEvent("player_spawned", OnPlayerSpawned);
}

public void OnConVarChanged(ConVar convar, const char[] oldVal, const char[] newVal)
{
	if (convar == g_ConVar_Distance) {
		g_fDistance = StringToFloat(newVal);
	} else if (convar == g_ConVar_CheckDelay) {
		g_fCheckDelay = StringToFloat(newVal);
	} else if (convar == g_ConVar_UndoDelay) {
		g_fUndoDelay = StringToFloat(newVal);
	}
}

public void OnPlayerSpawned(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_fCheckTime[client] = 0.0;
	ClearBit(g_iTagged, client);
	//Tag client if they are zombie to optimize loop
	if (ZR_IsClientZombie(client)) {
		SetBit(g_iSkip, client);
	} else {
		ClearBit(g_iSkip, client);
	}
	//Reset player visibility
	SetEntityRenderMode(client, RENDER_NONE);
	SetEntityRenderColor(client, 0,0,0,0); 
}

/**
 * Called after a client has become a zombie.
 * 
 * @param client            The client to infect.
 * @param attacker          The attacker who did the infect.
 * @param motherinfect      Indicates a mother zombie infect.
 * @param respawnoverride   Set to true to override respawn cvar.
 * @param respawn           Value to override with.
 * 
 * OnClientInfected(client, attacker = -1, bool:motherinfect = false, bool:respawnoverride = false, bool:respawn = false)
 */
public int ZR_OnClientInfected(int client, int attacker, bool motherinfect, bool respawnoverride, bool respawn)
{
	//Tag zombie player so they are removed from loop & reset their visibility
	SetBit(g_iSkip, client);
	SetEntityRenderMode(client, RENDER_NONE);
	SetEntityRenderColor(client, 0,0,0,0); 
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{	
	//Client is a zombie or something
	if (CheckBit(g_iSkip, client))
	{
		return Plugin_Continue;
	}
	
	//Just in case do this check
	if ((client <= 0) || (client > MaxClients)) {
		return Plugin_Continue;
	}
	
	//Skip invalid players
	if (!IsClientInGame(client) || !IsPlayerAlive(client) || ZR_IsClientZombie(client))
	{
		SetBit(g_iSkip, client);
		return Plugin_Continue;
	}
	
	//Client is transparent
	if (CheckBit(g_iTagged, client))
	{
		//Only perform check every 3000 miliseconds
		if (g_fUndoTime[client] > GetGameTime())
		{
			return Plugin_Continue;
		}
		
		//Initialize vector handles
		float clientOrigin[3], compOrigin[3];
		
		//Get the origin vector for client
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", clientOrigin);
		
		bool virginity = true;
		
		for (int i = 1; i <= MaxClients; i++)
		{
			//Skip invalid players
			if ((i == client) || !IsClientInGame(i) || !IsPlayerAlive(i))
			{
				continue;
			}
			
			//Skip iteration if player was tagged recently
			if (CheckBit(g_iTagged, i))
			{
				if (g_fUndoTime[i] > GetGameTime())
				{
					continue;
				}
			}
			
			//Don't compare me to a zombie
			if (CheckBit(g_iSkip, i))
			{
    			continue;
			}
			
			//Get the origin vector for victim
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", compOrigin);
			
			if (GetVectorDistance(clientOrigin, compOrigin) < g_fDistance)
			{
				if (!CheckBit(g_iTagged, i))
				{
					SetBit(g_iTagged, i);
					SetEntityRenderMode(i, RENDER_TRANSCOLOR);
					SetEntityRenderColor(i, 0,0,0,100);
				}
				g_fUndoTime[i] = GetGameTime() + g_fUndoDelay;
				g_fUndoTime[client] = GetGameTime() + g_fUndoDelay;
				virginity = false;
				break;
			}
		}
		
		if (virginity)
		{
			ClearBit(g_iTagged, client);
			SetEntityRenderMode(client, RENDER_NONE);
   			SetEntityRenderColor(client, 0,0,0,0);
   			g_fCheckTime[client] = GetGameTime() + g_fCheckDelay;
		}
		
	} else {
		//Only perform check every 1000 miliseconds
		if (g_fCheckTime[client] > GetGameTime())
		{
			return Plugin_Continue;
		}
		
		//Initialize vector handles
		float clientOrigin[3], compOrigin[3];
		
		//Get the origin vector for client
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", clientOrigin);
		
		for (int i = 1; i <= MaxClients; i++)
		{
			//Iteration is current player OR already transparent
			if ((i == client) || CheckBit(g_iTagged, i) || (g_fCheckTime[i] > GetGameTime()))
			{
				continue;
			}
			
			//Skip invalid players
			if (!IsClientInGame(i) || !IsPlayerAlive(i))
			{
				continue;
			}
			
			if (CheckBit(g_iSkip, i))
			{
    			continue;
			}
			
			//Get the origin vector for victim
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", compOrigin);
			
			if (GetVectorDistance(clientOrigin, compOrigin) < g_fDistance) {
				//Tag both players, make transparent and break the loop
				SetBit(g_iTagged, i);
				SetEntityRenderMode(i, RENDER_TRANSCOLOR);
				SetEntityRenderColor(i, 0,0,0,100);
				g_fUndoTime[i] = GetGameTime() + g_fUndoDelay;
				SetBit(g_iTagged, client);
				SetEntityRenderMode(client, RENDER_TRANSCOLOR);
				SetEntityRenderColor(client, 0,0,0,100);
				g_fUndoTime[client] = GetGameTime() + g_fUndoDelay;
				break;
			}
		}
		//If nothing happened, set the delay (1 second)
		if (!CheckBit(g_iTagged, client))
		{
			g_fCheckTime[client] = GetGameTime() + g_fCheckDelay;
		}
	}

	return Plugin_Continue;
}

stock bool IsValidClient(int client)
{
	if ((client <= 0) || (client > MaxClients)) {
		return false;
	}
	if (!IsClientInGame(client)) {
		return false;
	}
	if (!IsPlayerAlive(client)) {
		return false;
	}
	return true;
}  
