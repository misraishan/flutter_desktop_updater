#include "desktop_updater_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>
#include <VersionHelpers.h>

#pragma comment(lib, "Version.lib") // Link with Version.lib

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>

namespace desktop_updater
{

  // static
  void DesktopUpdaterPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarWindows *registrar)
  {
    auto channel =
        std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
            registrar->messenger(), "desktop_updater",
            &flutter::StandardMethodCodec::GetInstance());

    auto plugin = std::make_unique<DesktopUpdaterPlugin>();

    channel->SetMethodCallHandler(
        [plugin_pointer = plugin.get()](const auto &call, auto result)
        {
          plugin_pointer->HandleMethodCall(call, std::move(result));
        });

    registrar->AddPlugin(std::move(plugin));
  }

  DesktopUpdaterPlugin::DesktopUpdaterPlugin() {}

  DesktopUpdaterPlugin::~DesktopUpdaterPlugin() {}

  void RestartApp()
  { 
    printf("Restarting the application...\n");
    // Get the current executable file path
    char szFilePath[MAX_PATH];
    GetModuleFileNameA(NULL, szFilePath, MAX_PATH);

    // Child process
    wchar_t executable_path[MAX_PATH];
    GetModuleFileNameW(NULL, executable_path, MAX_PATH);

    printf("Executable path: %ls\n", executable_path);

    // Create backup folder if not exists
    CreateDirectoryW(L"backup", NULL);
    CreateDirectoryW(L"update", NULL);

    std::wstring exeName(executable_path);
    size_t pos = exeName.find_last_of(L"\\/");
    if (pos != std::wstring::npos) {
      exeName = exeName.substr(pos + 1);
    }
    std::wstring update_path = L"update\\" + exeName;
    CopyFileW(executable_path, update_path.c_str(), FALSE);

    // Remove existing backup files in backup folder
    WIN32_FIND_DATAW findFileData;
    HANDLE hFind = FindFirstFileW(L"backup\\*", &findFileData);
    if (hFind != INVALID_HANDLE_VALUE)
    {
      do
      {
        if (findFileData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)
        {
          continue;
        }
        std::wstring file_path = L"backup\\" + std::wstring(findFileData.cFileName);
        DeleteFileW(file_path.c_str());
      } while (FindNextFileW(hFind, &findFileData));
      FindClose(hFind);
    }

    // Rename current to backup
    std::wstring update_backup_path = L"backup\\" + exeName;
    CopyFileW(executable_path, update_backup_path.c_str(), FALSE);

    printf("Copying new version\n");

    // Copy every files in update folder to current folder
    WIN32_FIND_DATAW findData;
    HANDLE hFindUpdate = FindFirstFileW(L"update\\*", &findData);
    if (hFindUpdate != INVALID_HANDLE_VALUE)
    {
      do
      {
        if (!(findData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY))
        {
          std::wstring sourcePath = L"update\\" + std::wstring(findData.cFileName);
          std::wstring destPath = L"." L"\\" + std::wstring(findData.cFileName);
          CopyFileW(sourcePath.c_str(), destPath.c_str(), FALSE);

          printf("Copying %ls to %ls\n", sourcePath.c_str(), destPath.c_str());

          // check if error
          DWORD dwError = GetLastError();
          if (dwError != 0)
          {
            printf("Error: %d\n", dwError);
          }
        }
      } while (FindNextFileW(hFindUpdate, &findData));
      FindClose(hFindUpdate);
    }

    // Remove every files in backup folder
    WIN32_FIND_DATAW findDataBackup;
    HANDLE hFindBackup = FindFirstFileW(L"backup\\*", &findDataBackup);
    if (hFindBackup != INVALID_HANDLE_VALUE)
    {
      do
      {
        if (!(findDataBackup.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY))
        {
          std::wstring sourcePath = L"backup\\" + std::wstring(findDataBackup.cFileName);
          DeleteFileW(sourcePath.c_str());

          printf("Deleting %ls\n", sourcePath.c_str());
        }
      } while (FindNextFileW(hFindBackup, &findDataBackup));
      FindClose(hFindBackup);
    }

    // Remove backup folder
    RemoveDirectoryW(L"backup");

    // Remove every files in update folder
    WIN32_FIND_DATAW findDataUpdate;
    HANDLE hFindUpdate2 = FindFirstFileW(L"update\\*", &findDataUpdate);
    if (hFindUpdate2 != INVALID_HANDLE_VALUE)
    {
      do
      {
        if (!(findDataUpdate.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY))
        {
          std::wstring sourcePath = L"update\\" + std::wstring(findDataUpdate.cFileName);
          DeleteFileW(sourcePath.c_str());

          printf("Deleting %ls\n", sourcePath.c_str());
        }
      } while (FindNextFileW(hFindUpdate2, &findDataUpdate));
      FindClose(hFindUpdate2);
    }

    // Remove update folder
    RemoveDirectoryW(L"update");

    // Copy new version, replace path -> execatable path
    // CopyFileW(replace_path, executable_path, FALSE);

    printf("Starting new version\n");
    // Start new version
    STARTUPINFO si = {sizeof(si)};
    PROCESS_INFORMATION pi;
    CreateProcessW(executable_path, NULL, NULL, NULL, FALSE, 0, NULL, NULL, &si, &pi);

    // Close process and thread handles
    CloseHandle(pi.hProcess);
    CloseHandle(pi.hThread);

    ExitProcess(0);
  }

  void DesktopUpdaterPlugin::HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
  {
    if (method_call.method_name().compare("getPlatformVersion") == 0)
    {
      std::ostringstream version_stream;
      version_stream << "Windows ";
      if (IsWindows10OrGreater())
      {
        version_stream << "10+";
      }
      else if (IsWindows8OrGreater())
      {
        version_stream << "8";
      }
      else if (IsWindows7OrGreater())
      {
        version_stream << "7";
      }
      result->Success(flutter::EncodableValue(version_stream.str()));
    }
    else if (method_call.method_name().compare("restartApp") == 0)
    {
      RestartApp();
      result->Success();
    }
    else if (method_call.method_name().compare("getExecutablePath") == 0)
    {
      wchar_t executable_path[MAX_PATH];
      GetModuleFileNameW(NULL, executable_path, MAX_PATH);
      
      // Convert wchar_t to std::string (UTF-8)
      int size_needed = WideCharToMultiByte(CP_UTF8, 0, executable_path, -1, NULL, 0, NULL, NULL);
      std::string executablePathStr(size_needed, 0);
      WideCharToMultiByte(CP_UTF8, 0, executable_path, -1, &executablePathStr[0], size_needed, NULL, NULL);
      
      result->Success(flutter::EncodableValue(executablePathStr));
    }
    else if (method_call.method_name().compare("getCurrentVersion") == 0)
    {
      // Get only bundle version, Product version 1.0.0+2, should return 2
      wchar_t exePath[MAX_PATH];
      GetModuleFileNameW(NULL, exePath, MAX_PATH);
      
      DWORD verHandle = 0;
      UINT size = 0;
      LPBYTE lpBuffer = NULL;
      DWORD verSize = GetFileVersionInfoSizeW(exePath, &verHandle);
      if (verSize == NULL)
      {
          result->Error("VersionError", "Unable to get version size.");
          return;
      }

      std::vector<BYTE> verData(verSize);
      if (!GetFileVersionInfoW(exePath, verHandle, verSize, verData.data()))
      {
          result->Error("VersionError", "Unable to get version info.");
          return;
      }

      // Retrieve translation information
      struct LANGANDCODEPAGE {
          WORD wLanguage;
          WORD wCodePage;
      } *lpTranslate;

      UINT cbTranslate = 0;
      if (!VerQueryValueW(verData.data(), L"\\VarFileInfo\\Translation", 
                         (LPVOID*)&lpTranslate, &cbTranslate) || cbTranslate < sizeof(LANGANDCODEPAGE))
      {
          result->Error("VersionError", "Unable to get translation info.");
          return;
      }

      // Build the query string using the first translation
      wchar_t subBlock[50];
      swprintf(subBlock, 50, L"\\StringFileInfo\\%04x%04x\\ProductVersion", 
               lpTranslate[0].wLanguage, lpTranslate[0].wCodePage);

      if (!VerQueryValueW(verData.data(), subBlock, (LPVOID*)&lpBuffer, &size))
      {
          result->Error("VersionError", "Unable to query version value.");
          return;
      }

      std::wstring productVersion((wchar_t*)lpBuffer);
      size_t plusPos = productVersion.find(L'+');
      if (plusPos != std::wstring::npos && plusPos + 1 < productVersion.length())
      {
          std::wstring buildNumber = productVersion.substr(plusPos + 1);

          // Trim any trailing spaces
          buildNumber.erase(buildNumber.find_last_not_of(L' ') + 1);
          
          // Convert wchar_t to std::string (UTF-8)
          int size_needed = WideCharToMultiByte(CP_UTF8, 0, buildNumber.c_str(), -1, NULL, 0, NULL, NULL);
          std::string buildNumberStr(size_needed - 1, 0); // Exclude null terminator
          WideCharToMultiByte(CP_UTF8, 0, buildNumber.c_str(), -1, &buildNumberStr[0], size_needed - 1, NULL, NULL);

          result->Success(flutter::EncodableValue(buildNumberStr));
      }
      else
      {
          result->Error("VersionError", "Invalid version format.");
      }
    }
    else
    {
      result->NotImplemented();
    }
  }

} // namespace desktop_updater
