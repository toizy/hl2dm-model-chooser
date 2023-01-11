#pragma semicolon 1

// This source was recovered from my smx using SourceMod decompiler.
// It still looks a bit crazy.

#include <sourcemod> 
#include <sdktools>

public Extension:__ext_sdkhooks =
{
	name = "SDKHooks",
	file = "sdkhooks.ext",
	autoload = 1,
	required = 1,
};
new g_eCvars[32][132];
new g_iCvars;
public Plugin:myinfo =
{
	name = "SM SKINCHOOSER HL2DM",
	description = "Complete code refactoring has been made. Removed not needed and stupid code, added new features.",
	author = "Andi67 (toizy's fork)",
	version = "2.4",
	url = "http://www.sourcemod.net"
};
new Handle:g_version;
new Handle:kv;
new Handle:playermodelskv;
new String:authid[66][36];
new Handle:ArrayTeam0;
new Handle:ArrayTeam2;
new Handle:ArrayTeam3;
new ArrayTeam0Count;
new ArrayTeam2Count;
new ArrayTeam3Count;
new ArrayTeam0Iterator;
new ArrayTeam2Iterator;
new ArrayTeam3Iterator;
new bool:TeamPlay;
new bool:HasModel[66];
new String:CurrentPlayerModel[66][256];
new RandomModel[66];
new Handle:ViewBackTimer[66];
new String:LastMenuItem[66][32];
new CommentedLine;
new ConVar:g_SkinPreview;
new ConVar:g_Enabled;
new ConVar:g_AutoDisplay;
new ConVar:g_AdminOnly;
new ConVar:g_PlayerSpawnTimer;
new ConVar:g_ForcePlayerSkin;
new ConVar:g_HideMenuTimer;
new ConVar:g_GraduallyDownload;


public void OnPluginStart()
{
	g_version = CreateConVar("sm_skinchooser_hl2dm_version", "2.4", "SM SKINCHOOSER HL2DM VERSION", 256, false, 0.0, false, 0.0);
	SetConVarString(g_version, "2.4", false, false);
	g_Enabled = CreateConVar("sm_skinchooser_hl2dm_enabled", "1", "", 0, false, 0.0, false, 0.0);
	g_AutoDisplay = CreateConVar("sm_skinchooser_hl2dm_autodisplay", "1", "", 0, false, 0.0, false, 0.0);
	g_AdminOnly = CreateConVar("sm_skinchooser_hl2dm_adminonly", "0", "", 0, false, 0.0, false, 0.1);
	g_PlayerSpawnTimer = CreateConVar("sm_skinchooser_hl2dm_playerspawntimer", "1", "", 0, false, 0.0, false, 0.0);
	g_ForcePlayerSkin = CreateConVar("sm_skinchooser_hl2dm_forceplayerskin", "1", "", 0, false, 0.0, false, 0.0);
	g_SkinPreview = CreateConVar("sm_skinchooser_hl2dm_preview", "1", "", 0, false, 0.0, false, 0.0);
	g_HideMenuTimer = CreateConVar("sm_skinchooser_hl2dm_hidemenutimer", "60", "", 0, true, 1.0, true, 3600.0);
	g_GraduallyDownload = CreateConVar("sm_skinchooser_hl2dm_graduallydownload", "5", "", 0, false, 0.0, false, 0.0);
	AutoExecConfig(true, "sm_skinchooser_hl2dm", "sourcemod");
	ArrayTeam0 = CreateArray(256, 0);
	ArrayTeam2 = CreateArray(256, 0);
	ArrayTeam3 = CreateArray(256, 0);
	RegConsoleCmd("models", Command_Model, "", 0);
	RegConsoleCmd("skins", Command_Model, "", 0);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Post);
	new String:file[256];
	BuildPath(PathType:0, file, 255, "data/skinchooser_playermodels.ini");
	playermodelskv = CreateKeyValues("Models", "", "");
	FileToKeyValues(playermodelskv, file);
	new i = 1;
	while (i <= MaxClients)
	{
		new var1;
		if (IsClientConnected(i) && IsClientAuthorized(i))
		{
			OnClientPostAdminCheck(i);
		}
		i++;
	}
	CommentedLine = 0;
}

public void OnPluginEnd()
{
	CloseHandle(g_version);
	CloseHandle(ArrayTeam0);
	CloseHandle(ArrayTeam2);
	CloseHandle(ArrayTeam3);
	new String:file[256];
	BuildPath(PathType:0, file, 255, "data/skinchooser_playermodels.ini");
	KeyValuesToFile(playermodelskv, file);
	CloseHandle(playermodelskv);
}

public void OnMapStart()
{
	if (GetConVarInt(g_Enabled) == 1)
	{
		new Handle:hTeamPlay = FindConVar("mp_teamplay");
		if (hTeamPlay)
		{
			TeamPlay = GetConVarBool(hTeamPlay);
		}
		else
		{
			TeamPlay = false;
		}
		ArrayTeam0Count = LoadModels(ArrayTeam0, "configs/sm_skinchooser_hl2dm/forceskinsplayer_dm.ini");
		ArrayTeam2Count = LoadModels(ArrayTeam2, "configs/sm_skinchooser_hl2dm/forceskinsplayer_team2.ini");
		ArrayTeam3Count = LoadModels(ArrayTeam3, "configs/sm_skinchooser_hl2dm/forceskinsplayer_team3.ini");
		new String:file[256];
		new String:path[100];
		kv = CreateKeyValues("Commands", "", "");
		if (TeamPlay)
		{
			BuildPath(PathType:0, file, 255, "configs/sm_skinchooser_hl2dm/skins_tdm.ini");
		}
		else
		{
			BuildPath(PathType:0, file, 255, "configs/sm_skinchooser_hl2dm/skins_dm.ini");
		}
		FileToKeyValues(kv, file);
		if (KvGotoFirstSubKey(kv, true))
		{
			do {
				if (KvJumpToKey(kv, "Team1", false))
				{
					if (KvGotoFirstSubKey(kv, true))
					{
						KvGetString(kv, "path", path, 100, "");
						while (FileExists(path, false, "GAME"))
						{
							PrecacheModel(path, true);
							if (!(KvGotoNextKey(kv, true)))
							{
								KvGoBack(kv);
							}
						}
						if (!(KvGotoNextKey(kv, true)))
						{
							KvGoBack(kv);
						}
					}
					KvGoBack(kv);
				}
				if (KvJumpToKey(kv, "Team2", false))
				{
					if (KvGotoFirstSubKey(kv, true))
					{
						KvGetString(kv, "path", path, 100, "");
						while (FileExists(path, false, "GAME"))
						{
							PrecacheModel(path, true);
							if (!(KvGotoNextKey(kv, true)))
							{
								KvGoBack(kv);
							}
						}
						if (!(KvGotoNextKey(kv, true)))
						{
							KvGoBack(kv);
						}
					}
					KvGoBack(kv);
				}
			} while (KvGotoNextKey(kv, true));
			KvRewind(kv);
		}
		ReadDownloads();
	}
}

public void OnMapEnd()
{
	CloseHandle(kv);
}

CheckAdminFlag(String:Flags[], client)
{
	if (GetUserAdmin(client) == -1)
	{
		return Plugin_Continue;
	}
	new bool:Result = 1;
	new flags = GetUserFlagBits(client);
	new size = strlen(Flags);
	size--;
	new x;
	while (Flags[x] && x < size)
	{
		Flags[x] = CharToLower(Flags[x]);
		new var2;
		if (Flags[x] == 'a' && flags & 1)
		{
			new var3;
			if (Flags[x] == 'b' && flags & 2)
			{
				new var4;
				if (Flags[x] == 'c' && flags & 4)
				{
					new var5;
					if (Flags[x] == 'd' && flags & 8)
					{
						new var6;
						if (Flags[x] == 'e' && flags & 16)
						{
							new var7;
							if (Flags[x] == 'f' && flags & 32)
							{
								new var8;
								if (Flags[x] == 'g' && flags & 64)
								{
									new var9;
									if (Flags[x] == 'h' && flags & 128)
									{
										new var10;
										if (Flags[x] == 'i' && flags & 256)
										{
											new var11;
											if (Flags[x] == 'j' && flags & 512)
											{
												new var12;
												if (Flags[x] == 'k' && flags & 1024)
												{
													new var13;
													if (Flags[x] == 'l' && flags & 2048)
													{
														new var14;
														if (Flags[x] == 'm' && flags & 4096)
														{
															new var15;
															if (Flags[x] == 'n' && flags & 8192)
															{
																new var16;
																if (Flags[x] == 'o' && flags & 32768)
																{
																	new var17;
																	if (Flags[x] == 'p' && flags & 65536)
																	{
																		new var18;
																		if (Flags[x] == 'q' && flags & 131072)
																		{
																			new var19;
																			if (Flags[x] == 'r' && flags & 262144)
																			{
																				new var20;
																				if (Flags[x] == 's' && flags & 524288)
																				{
																					new var21;
																					if (Flags[x] == 't' && flags & 1048576)
																					{
																						new var22;
																						if (Flags[x] == 'z' && flags & 16384)
																						{
																							Result = false;
																						}
																					}
																				}
																			}
																		}
																	}
																}
															}
														}
													}
												}
											}
										}
									}
								}
							}
						}
					}
				}
			}
		}
		x++;
	}
	return Result;
}

Handle:BuildMainMenu(client)
{
	if (!KvGotoFirstSubKey(kv, true))
	{
		return Handle:0;
	}
	new Handle:menu = CreateMenu(Menu_Group, MenuAction:28);
	decl String:buffer[32];
	decl String:accessFlag[8];
	new AdminId:admin = GetUserAdmin(client);
	do {
		new bool:Found;
		new String:group[32];
		new String:temp[4];
		KvGetString(kv, "Admin", group, 30, "");
		new count = GetAdminGroupCount(admin);
		new i;
		while (i < count)
		{
			if (GetAdminGroup(admin, i, temp, 2) == FindAdmGroup(group))
			{
				KvGetSectionName(kv, buffer, 30);
				AddMenuItem(menu, buffer, buffer, 0);
				Found = true;
				if (!Found)
				{
					KvGetString(kv, "admin", accessFlag, 5, "");
					new var1;
					if (StrEqual(accessFlag, "", true) || CheckAdminFlag(accessFlag, client))
					{
						KvGetSectionName(kv, buffer, 30);
						AddMenuItem(menu, buffer, buffer, 0);
					}
				}
			}
			i++;
		}
		if (!Found)
		{
			KvGetString(kv, "admin", accessFlag, 5, "");
			new var1;
			if (StrEqual(accessFlag, "", true) || CheckAdminFlag(accessFlag, client))
			{
				KvGetSectionName(kv, buffer, 30);
				AddMenuItem(menu, buffer, buffer, 0);
			}
		}
	} while (KvGotoNextKey(kv, true));
	KvRewind(kv);
	AddMenuItem(menu, "none", "None", 0);
	SetMenuTitle(menu, "Skins");
	return menu;
}

bool:StartsWith(String:str[], String:subString[])
{
	new n;
	while (subString[n])
	{
		new var1;
		if (str[n] && subString[n] == str[n])
		{
			return false;
		}
		n++;
	}
	return true;
}

public ReadDownloads()
{
	new String:file[256];
	BuildPath(PathType:0, file, 255, "configs/sm_skinchooser_hl2dm/skinchooserdownloads.ini");
	new Handle:fileh = OpenFile(file, "r", false, "GAME");
	new String:buffer[256];
	if (fileh)
	{
		new i;
		new String:str[512];
		new GraduallyDownload = GetConVarInt(g_GraduallyDownload);
		while (!IsEndOfFile(fileh) && ReadFileLine(fileh, buffer, 256))
		{
			new var2;
			if (StartsWith(buffer, "//") && GraduallyDownload > 0)
			{
				new var3;
				if (i >= CommentedLine && i < GraduallyDownload + CommentedLine)
				{
					ReplaceString(buffer, 256, "//", "", true);
					Format(str, 512, "CommentedLine %i, i %i", CommentedLine, i);
					ReadFileOrFolder(buffer);
				}
				i++;
			}
			else
			{
				ReadFileOrFolder(buffer);
			}
		}
		if (0 < GraduallyDownload)
		{
			CommentedLine = GraduallyDownload + CommentedLine;
			if (CommentedLine > i)
			{
				Format(str, 512, "CommentedLine %i, i %i", CommentedLine, i);
				CommentedLine = 0;
			}
		}
		if (fileh)
		{
			CloseHandle(fileh);
		}
	}
	return Plugin_Continue;
}

public ReadFileOrFolder(String:path[])
{
	new Handle:dirh;
	new String:buffer[256];
	new String:tmp_path[256];
	new FileType:type;
	TrimString(path);
	if (DirExists(path, false, "GAME"))
	{
		dirh = OpenDirectory(path, false, "GAME");
		while (ReadDirEntry(dirh, buffer, 256, type))
		{
			TrimString(buffer);
			new var1;
			if (!StrEqual(buffer, "", false) && !StrEqual(buffer, ".", false) && !StrEqual(buffer, "..", false))
			{
				strcopy(tmp_path, 255, path);
				StrCat(tmp_path, 255, "/");
				StrCat(tmp_path, 255, buffer);
				if (type == FileType:2)
				{
					PrecacheAndDownload(tmp_path);
				}
			}
		}
	}
	else
	{
		PrecacheAndDownload(path);
	}
	if (dirh)
	{
		CloseHandle(dirh);
	}
	return Plugin_Continue;
}

public PrecacheAndDownload(String:buffer[])
{
	PrecacheModel(buffer, true);
	if (FileExists(buffer, false, "GAME"))
	{
		AddFileToDownloadsTable(buffer);
	}
	return Plugin_Continue;
}

Show_Menu(String:ItemText[], Idx, client)
{
	if (StrEqual(ItemText, "none", true))
	{
		KvJumpToKey(playermodelskv, authid[client], true);
		if (TeamPlay)
		{
			if (GetClientTeam(client) == 2)
			{
				KvSetString(playermodelskv, "Team1", "");
			}
			else
			{
				if (GetClientTeam(client) == 3)
				{
					KvSetString(playermodelskv, "Team2", "");
				}
			}
		}
		else
		{
			KvSetString(playermodelskv, "Team1", "");
		}
		KvRewind(playermodelskv);
		new var1;
		if (GetConVarInt(g_ForcePlayerSkin) == 1 && GetConVarInt(g_PlayerSpawnTimer) == 1)
		{
			skin_players(client);
		}
		return Plugin_Continue;
	}
	KvJumpToKey(kv, ItemText, false);
	if (TeamPlay)
	{
		if (GetClientTeam(client) == 2)
		{
			KvJumpToKey(kv, "Team1", false);
		}
		else
		{
			if (GetClientTeam(client) == 3)
			{
				KvJumpToKey(kv, "Team2", false);
			}
			return Plugin_Continue;
		}
	}
	else
	{
		KvJumpToKey(kv, "Team1", false);
	}
	KvGotoFirstSubKey(kv, true);
	new Handle:tempmenu = CreateMenu(Menu_Model, MenuAction:28);
	decl String:SectionName[20];
	decl String:path[256];
	decl String:skin[4];
	decl String:result[256];
	do {
		KvGetSectionName(kv, SectionName, 20);
		KvGetString(kv, "path", path, 256, "");
		KvGetString(kv, "skin", skin, 3, "0");
		result = "";
		StrCat(result, 256, path);
		StrCat(result, 256, "|");
		StrCat(result, 256, skin);
		StrCat(result, 256, "|");
		AddMenuItem(tempmenu, result, SectionName, 0);
	} while (KvGotoNextKey(kv, true));
	SetMenuTitle(tempmenu, ItemText);
	KvRewind(kv);
	DisplayMenuAtItem(tempmenu, client, Idx, GetConVarInt(g_HideMenuTimer));
	return Plugin_Continue;
}

public Menu_Group(Handle:menu, MenuAction:action, client, option)
{
	if (action == MenuAction:MenuAction_End)
	{
		CloseHandle(menu);
		return Plugin_Continue;
	}
	if (action == MenuAction:MenuAction_Select)
	{
		//TODO
		//if (!GetMenuItem(menu, option, LastMenuItem[client], 32, 0, "", 0))
		if (!GetMenuItem(menu, option, LastMenuItem[client], 32))
		{
			return Plugin_Continue;
		}
		Show_Menu(LastMenuItem[client], 0, client);
	}
	return Plugin_Continue;
}

public Menu_Model(Handle:menu, MenuAction:action, client, option)
{
	if (action == MenuAction:MenuAction_End)
	{
		CloseHandle(menu);
		return Plugin_Continue;
	}
	if (action == MenuAction:MenuAction_Select)
	{
		new String:ItemText[256];
		if (!GetMenuItem(menu, option, ItemText, sizeof(ItemText)))
		{
			return Plugin_Continue;
		}
		new String:buffer[2][256] = {
			"|",
			"OV"
		};
		ExplodeString(ItemText, "|", buffer, 2, 256, false);
		SetModel(client, buffer[0], buffer[1]);
		SetThirdperson(client);
		KvJumpToKey(playermodelskv, authid[client], true);
		if (TeamPlay)
		{
			if (GetClientTeam(client) == 2)
			{
				KvSetString(playermodelskv, "Team1", ItemText);
			}
			else
			{
				if (GetClientTeam(client) == 3)
				{
					KvSetString(playermodelskv, "Team2", ItemText);
				}
			}
		}
		else
		{
			KvSetString(playermodelskv, "Team1", ItemText);
		}
		KvRewind(playermodelskv);
		Show_Menu(LastMenuItem[client], GetMenuSelectionPosition(), client);
	}
	return Plugin_Continue;
}

public void OnClientPutInServer(client)
{
	HasModel[client] = 0;
}

public void OnClientPostAdminCheck(client)
{
	if (GetClientAuthId(client, AuthIdType:3, authid[client], 35, true))
	{
		if (GetConVarBool(g_AutoDisplay))
		{
			CreateTimer(5.0, Timer_Menu, client, 0);
		}
	}
}

public Action:Command_Model(client, args)
{
	if (GetConVarInt(g_Enabled) == 1)
	{
		if (!IsClientInGame(client))
		{
			return Plugin_Handled;
		}
		new Handle:mainmenu = BuildMainMenu(client);
		if (mainmenu)
		{
			if (GetConVarBool(g_AdminOnly) && GetUserAdmin(client) == 0)
			{
				return Plugin_Handled;
			}
			
			if ((GetConVarBool(g_AdminOnly) && GetUserAdmin(client) != -1) || !GetConVarBool(g_AdminOnly))
			{
				DisplayMenu(mainmenu, client, GetConVarInt(g_HideMenuTimer));
			}
		}
	}
	return Plugin_Handled;
}

public Action:Timer_Menu(Handle:timer, any:client)
{
	new var1;
	if (GetConVarInt(g_Enabled) == 1 && IsClientConnected(client) && !GetClientMenu(client, Handle:0))
	{
		new Handle:mainmenu = BuildMainMenu(client);
		if (mainmenu)
		{
			DisplayMenu(mainmenu, client, GetConVarInt(g_HideMenuTimer));
		}
	}
	return Action:3;
}

public Event_PlayerTeam(Handle:event, String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(g_Enabled) != 1)
	{
		return Plugin_Continue;
	}
	if (GetConVarBool(g_AutoDisplay))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid", 0));
		new team = GetEventInt(event, "team", 0);
		if (TeamPlay)
		{
			new var1;
			if ((team == 2 || team == 3) && IsClientInGame(client))
			{
				Command_Model(client, 0);
			}
			return Plugin_Continue;
		}
		if ((team && team == 2) && IsClientInGame(client))
		{
			Command_Model(client, 0);
		}
	}
	return Plugin_Continue;
}

public Event_PlayerSpawn(Handle:event, String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(g_Enabled) == 1)
	{
		new clientId = GetEventInt(event, "userid", 0);
		new client = GetClientOfUserId(clientId);
		if (!IsValidClient(client))
		{
			return Plugin_Continue;
		}
		if (GetConVarInt(g_PlayerSpawnTimer) == 1)
		{
			CreateTimer(1.0, Timer_Spawn, client, 0);
		}
		else
		{
			Timer_Spawn(Handle:0, client);
		}
	}
	return Plugin_Continue;
}

public Action:Timer_Spawn(Handle:timer, any:client)
{
	if (!IsClientInGame(client))
	{
		return Action:0;
	}
	KvJumpToKey(playermodelskv, authid[client], true);
	new String:model[256];
	if (TeamPlay)
	{
		if (GetClientTeam(client) == 2)
		{
			KvGetString(playermodelskv, "Team1", model, 256, "");
		}
		else
		{
			if (GetClientTeam(client) == 3)
			{
				KvGetString(playermodelskv, "Team2", model, 256, "");
			}
		}
	}
	else
	{
		KvGetString(playermodelskv, "Team1", model, 256, "");
	}
	if (strlen(model))
	{
		new String:buffer[2][256] = {
			"|",
			"------------------------------------------------------------"
		};
		ExplodeString(model, "|", buffer, 2, 256, false);
		// TODO
		//SetModel(client, buffer[0][buffer], buffer[1]);
		SetModel(client, buffer[0], buffer[1]);
	}
	else
	{
		if (GetConVarInt(g_ForcePlayerSkin) == 1)
		{
			if (!HasModel[client])
			{
				skin_players(client);
			}
		}
	}
	KvRewind(playermodelskv);
	return Action:0;
}

LoadModels(Handle:Array, String:ini_file[])
{
	decl String:buffer[256];
	decl String:file[256];
	ClearArray(Array);
	BuildPath(PathType:0, file, 256, ini_file);
	new Handle:fileh = OpenFile(file, "r", false, "GAME");
	while (ReadFileLine(fileh, buffer, 256))
	{
		TrimString(buffer);
		if (FileExists(buffer, false, "GAME"))
		{
			AddFileToDownloadsTable(buffer);
		}
		if (StrEqual(buffer[strlen(buffer) + -4], ".mdl", false))
		{
			if (PrecacheModel(buffer, true))
			{
				PushArrayString(Array, buffer);
			}
		}
	}
	new ArraySize = GetArraySize(Array);
	decl R;
	new i;
	while (i < ArraySize)
	{
		R = GetRandomInt(0, ArraySize + -1);
		SwapArrayItems(Array, i, R);
		i++;
	}
	return ArraySize;
}

Iterate(&Iterator, Count, client)
{
	RandomModel[client] = Iterator;
	new var1 = Iterator;
	var1++;
	Iterator = var1;
	if (Count == Iterator)
	{
		Iterator = 0;
	}
	return Plugin_Continue;
}

skin_players(client)
{
	new String:ModelPath[256];
	if (TeamPlay)
	{
		new team = GetClientTeam(client);
		if (team == 2)
		{
			GetArrayString(ArrayTeam2, ArrayTeam2Iterator, ModelPath, 256);
			SetModel(client, ModelPath, "0");
			Iterate(ArrayTeam2Iterator, ArrayTeam2Count, client);
		}
		else
		{
			if (team == 3)
			{
				GetArrayString(ArrayTeam3, ArrayTeam3Iterator, ModelPath, 256);
				SetModel(client, ModelPath, "0");
				Iterate(ArrayTeam3Iterator, ArrayTeam3Count, client);
			}
		}
	}
	else
	{
		GetArrayString(ArrayTeam0, ArrayTeam0Iterator, ModelPath, 256);
		SetModel(client, ModelPath, "0");
		Iterate(ArrayTeam0Iterator, ArrayTeam0Count, client);
	}
	return Plugin_Continue;
}

SetModel(client, String:ModelName[], String:Skin[])
{
	new var1;
	if (client > 0 && client <= MaxClients && IsValidEntity(client) && IsClientConnected(client) && IsModelPrecached(ModelName))
	{
		new m_nSkin = StringToInt(Skin, 10);
		HasModel[client] = true;
		strcopy(CurrentPlayerModel[client], 256, ModelName);
		SetEntityFlags(client, GetEntityFlags(client) | 1);
		SetEntityModel(client, ModelName);
		SetEntityRenderColor(client, 255, 255, 255, 255);
		SetEntProp(client, PropType:0, "m_nSkin", m_nSkin, 4, 0);
	}
	return Plugin_Continue;
}

bool:IsValidClient(client)
{
	if (0 >= client)
	{
		return false;
	}
	if (client > MaxClients)
	{
		return false;
	}
	if (!IsClientConnected(client))
	{
		return false;
	}
	return IsClientInGame(client);
}

public SetThirdperson(client)
{
	if (IsPlayerAlive(client))
	{
		Thirdperson(client, true);
		ViewBackTimer[client] = CreateTimer(30.0, Timer_ThirdPersonOff, client, 0);
	}
	return Plugin_Continue;
}

public Action:Timer_ThirdPersonOff(Handle:timer, any:client)
{
	IsThirdperson(client);
	ViewBackTimer[client] = Handle:0;
	return Action:0;
}

Thirdperson(client, bool:Enable)
{
	if (!GetConVarBool(g_SkinPreview))
	{
		return Plugin_Continue;
	}
	new var1;
	if (Enable && client > 0 && client <= MaxClients)
	{
		SetEntPropEnt(client, PropType:0, "m_hObserverTarget", 0, 0);
		SetEntProp(client, PropType:0, "m_iObserverMode", any:1, 4, 0);
		SetEntProp(client, PropType:0, "m_bDrawViewmodel", any:0, 4, 0);
		SetEntProp(client, PropType:0, "m_iFOV", any:100, 4, 0);
	}
	else
	{
		SetEntPropEnt(client, PropType:0, "m_hObserverTarget", client, 0);
		SetEntProp(client, PropType:0, "m_iObserverMode", any:0, 4, 0);
		SetEntProp(client, PropType:0, "m_bDrawViewmodel", any:1, 4, 0);
		SetEntProp(client, PropType:0, "m_iFOV", any:90, 4, 0);
	}
	return Plugin_Continue;
}

IsThirdperson(client)
{
	if (client > 0 && client <= MaxClients && IsValidEntity(client))
	{
		return GetEntProp(client, PropType:0, "m_iObserverMode", 4, 0) == 1;
	}
	return Plugin_Continue;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (!IsThirdperson(client))
	{
		return Plugin_Continue;
	}
	if (buttons & 32 || buttons & 2 || buttons & 8 || buttons & 16 || buttons & 512 || buttons & 1024)
	{
		Thirdperson(client, false);
	}
	return Plugin_Continue;
}