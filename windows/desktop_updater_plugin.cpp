#include "desktop_updater_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

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
    else
    {
      result->NotImplemented();
    }
  }

} // namespace desktop_updater
