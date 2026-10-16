// ================== DOUBLE INCLUDE ========================= //

#if defined _GlobalAPI_Stocks_included_
#endinput
#endif
#define _GlobalAPI_Stocks_included_

// =========================================================== //

/**
 * Gets plugin's display name from its handle
 *
 * @param plugin                Plugin handle to retrieve name from
 * @return                        String representation of the plugin name
 */
stock void GetPluginDisplayName(Handle plugin, char[] pluginName, int maxlength)
{
    if (!GetPluginInfo(plugin, PlInfo_Name, pluginName, maxlength))
    {
        strcopy(pluginName, maxlength, "Unknown");
    }
}

/**
 * Gets plugin's version from its handle
 *
 * @param plugin                Plugin handle to retrieve version from
 * @return                        String representation of the plugin version
 */
stock void GetPluginVersion(Handle plugin, char[] pluginVersion, int maxlength)
{
    if (!GetPluginInfo(plugin, PlInfo_Version, pluginVersion, maxlength))
    {
        strcopy(pluginVersion, maxlength, "Unknown");
    }
}

/**
 * Gets current map's "display name"
 *
 * @param buffer                Buffer to store the result in
 * @param maxlength                Max length of the buffer
 * @noreturn
 */
stock void GetMapDisplay(char[] buffer, int maxlength)
{
    char map[PLATFORM_MAX_PATH];
    GetCurrentMap(map, sizeof(map));
    GetMapDisplayName(map, map, sizeof(map));

    FormatEx(buffer, maxlength, map);
}

/**
 * Gets current map's full (game dir) path
 *
 * @param buffer                Buffer to store result in
 * @param maxlength                Max length of the buffer
 * @noreturn
 */
stock void GetMapFullPath(char[] buffer, int maxlength)
{
    char mapPath[PLATFORM_MAX_PATH];
    GetCurrentMap(mapPath, sizeof(mapPath));

    Format(buffer, maxlength, "maps/%s.bsp", mapPath);
}

/**
 * Gets whether a character can be used in an url as is
 *
 * @param character             Character to check
 * @return                      Whether the character is url safe
 */
stock bool IsUrlSafeChar(int character)
{
    // Control characters, space and anything non-ascii
    if (character <= 0x20 || character >= 0x7F)
    {
        return false;
    }

    switch (character)
    {
        case '%', '#', '?', '&', '=', '+', '/', '"', '<', '>', '|', '\\', '^', '`', '{', '}', '[', ']':
        {
            return false;
        }
    }

    return true;
}

/**
 * Percent-encodes the characters that would break an url
 *
 * @note                        Characters that are legal as is, such as ':', are kept
 * @param value                 Value to encode
 * @param buffer                Buffer to store the result in
 * @param maxlength             Max length of the buffer
 * @noreturn
 */
stock void URLEncode(const char[] value, char[] buffer, int maxlength)
{
    char hexChars[] = "0123456789ABCDEF";

    int pos = 0;

    for (int i = 0; value[i] != '\0'; i++)
    {
        int character = value[i] & 0xFF;

        if (IsUrlSafeChar(character))
        {
            if (pos + 1 >= maxlength)
            {
                break;
            }

            buffer[pos++] = character;
        }
        else
        {
            if (pos + 3 >= maxlength)
            {
                break;
            }

            buffer[pos++] = '%';
            buffer[pos++] = hexChars[character >> 4];
            buffer[pos++] = hexChars[character & 0x0F];
        }
    }

    buffer[pos] = '\0';
}

// TODO: Docs
stock bool TryCreateDirectory(char directory[PLATFORM_MAX_PATH])
{
	if (DirExists(directory))
	{
		return true;
	}

	if (!CreateDirectory(directory, 511))
	{
		LogError("Failed to create directory %s", directory);
		return false;
	}

	return true;
}
