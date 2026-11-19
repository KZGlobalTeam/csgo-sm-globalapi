bool HTTPPost(GlobalAPIRequestData hData)
{
    if (hData.KeyRequired && !gB_usingAPIKey && !gCV_Debug.BoolValue)
    {
        LogMessage("[GlobalAPI] Using this method requires an API key, and you dont seem to have one setup!");
        CleanupRequestData(hData);
        return false;
    }

    char requestUrl[GlobalAPI_Max_QueryUrl_Length];
    hData.GetString("url", requestUrl, sizeof(requestUrl));

    GlobalAPIRequest request = new GlobalAPIRequest(requestUrl, k_EHTTPMethodPOST);

    if (request == null)
    {
        CleanupRequestData(hData);
        return false;
    }

    if (hData.ContentType == GlobalAPIRequestContentType_OctetStream)
    {
        char file[PLATFORM_MAX_PATH];
        hData.GetString("bodyFile", file, sizeof(file));

        if (!FileExists(file) || !request.SetBodyFromFile(hData, file))
        {
            LogError("[GlobalAPI] Could not set request body from file %s", file);

            delete request;
            CleanupRequestData(hData);
            return false;
        }
    }
    else
    {
        int maxlength = hData.BodyLength;
        char[] body = new char[maxlength];

        hData.Encode(body, maxlength);
        request.SetBody(hData, body, strlen(body));
    }

    request.SetData(hData);
    request.SetTimeout(15);
    request.SetCallbacks();
    request.SetPoweredByHeader();
    request.SetEnvironmentHeaders(gC_MetamodVersion, gC_SourcemodVersion);
    request.SetAcceptHeaders(hData);
    request.SetContentTypeHeader(hData);
    request.SetRequestOriginHeader(hData);
    request.SetAuthenticationHeader(gC_apiKey);

    if (!request.Send(hData))
    {
        LogError("[GlobalAPI] Could not send request to \"%s\"", requestUrl);

        delete request;
        CleanupRequestData(hData);
        return false;
    }

    return true;
}
