public void Global_HTTP_Started(Handle request, GlobalAPIRequestData hData)
{
    hData.SetFloat("_requestStartTime", GetEngineTime());
    hData.SetHidden("_requestStartTime", true);

    Call_Global_OnRequestStarted(request, hData);
}

public void Global_HTTP_Completed(Handle request, bool failure, bool requestSuccessful, EHTTPStatusCode statusCode, GlobalAPIRequestData hData)
{
    hData.Status = view_as<int>(statusCode);
    hData.Failure = (failure || !requestSuccessful || !IsHTTPStatusSuccess(statusCode));
    hData.ResponseTime = CalculateResponseTime(hData);

    Call_Global_OnRequestFinished(request, hData);

    if (hData.Failure)
    {
        Call_Global_OnRequestFailed(request, hData);
        CallForward_NoResponse(hData);
    }

    else
    {
        int responseBodySize = 0;
        SteamWorks_GetHTTPResponseBodySize(request, responseBodySize);

        if (responseBodySize <= 0)
        {
            CallForward_NoResponse(hData);
        }
        // Replays are larger than the plugin heap, so they never pass through a string
        else if (hData.AcceptType == GlobalAPIRequestAcceptType_OctetStream)
        {
            SaveResponseBody(request, hData);
            CallForward_NoResponse(hData);
        }
        else if (!SteamWorks_GetHTTPResponseBodyCallback(request, Global_HTTP_Data, hData))
        {
            CallForward_NoResponse(hData);
        }
    }

    delete request;
}

public void Global_HTTP_Data(const char[] response, GlobalAPIRequestData hData)
{
    GlobalAPI_DebugMessage("HTTP Response data...");

    JSON_Object hJson = json_decode(response);

    if (hJson == null)
    {
        hJson = DecodeBareValue(response);
    }

    any data = hData.Data;
    Handle hFwd = hData.Callback;

    CallForward(hFwd, hJson, hData, data);

    // Cleanup
    json_cleanup_and_delete(hJson);
    json_cleanup_and_delete(hData);

    delete hFwd;
}

// =====[ PRIVATE ]=====

static void SaveResponseBody(Handle request, GlobalAPIRequestData hData)
{
    char path[PLATFORM_MAX_PATH];

    // Downloads finishing in the same frame get the same time
    for (int i = 0; ; i++)
    {
        BuildPath(Path_SM, path, sizeof(path), "data/GlobalAPI/%d_%f_%d.%s",
                                                GetTime(),
                                                GetEngineTime(),
                                                i,
                                                GlobalAPI_Data_File_Extension);

        if (!FileExists(path))
        {
            break;
        }
    }

    if (SteamWorks_WriteHTTPResponseBodyToFile(request, path))
    {
        hData.AddDataPath(path);
    }
    else
    {
        LogError("[GlobalAPI] Could not write response body to %s", path);
    }
}

// records/place returns a bare number, which json_decode does not accept,
// so it is passed on as {"result": value}
static JSON_Object DecodeBareValue(const char[] response)
{
    int length = strlen(response) + 12;
    char[] wrapped = new char[length];
    FormatEx(wrapped, length, "{\"result\":%s}", response);

    JSON_Object hJson = json_decode(wrapped);

    // A "null" response stays null, callers check for that
    if (hJson != null && hJson.GetType("result") == JSON_Type_Object)
    {
        json_cleanup_and_delete(hJson);
    }

    return hJson;
}

static int CalculateResponseTime(GlobalAPIRequestData hData)
{
    float timeNow = GetEngineTime();
    float startTime = hData.GetFloat("_requestStartTime");

    // Remove temporary key
    hData.Remove("_requestStartTime");

    return RoundFloat((timeNow - startTime) * 1000);
}
