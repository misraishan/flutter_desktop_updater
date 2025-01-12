#include "desktop_updater_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>
#include <VersionHelpers.h>
#include <Shlwapi.h> // Include Shlwapi.h for PathFileExistsW

#pragma comment(lib, "Version.lib") // Link with Version.lib
#pragma comment(lib, "Shlwapi.lib") // Link with Shlwapi.lib

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>
#include <filesystem> // Add filesystem header

#include <iostream>
#include <fstream>
#include <cstdlib>
#include <windows.h>
#include <filesystem>
#include <shlwapi.h>

namespace fs = std::filesystem;
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

  // Add recursive directory listing function
  void ListDirectoryContents(const std::wstring& path, int level = 0) {
      std::wstring indent(level * 2, L' ');
      WIN32_FIND_DATAW findData;
      std::wstring searchPath = path + L"\\*";
      
      HANDLE hFind = FindFirstFileW(searchPath.c_str(), &findData);
      if (hFind == INVALID_HANDLE_VALUE) {
          printf("Failed to list directory: %ls (Error: %d)\n", path.c_str(), GetLastError());
          return;
      }

      do {
          if (wcscmp(findData.cFileName, L".") == 0 || wcscmp(findData.cFileName, L"..") == 0)
              continue;

          std::wstring fullPath = path + L"\\" + findData.cFileName;
          printf("%ls%ls%ls\n", indent.c_str(), findData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY ? L"[DIR] " : L"", findData.cFileName);

          if (findData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) {
              ListDirectoryContents(fullPath, level + 1);
          }
      } while (FindNextFileW(hFind, &findData));

      FindClose(hFind);
  }

  // Add the copyAndReplaceFiles function
  // Copies and replaces files from sourcePath to destinationPath
  void copyAndReplaceFiles(const std::wstring& sourcePath, const std::wstring& destinationPath) {
    WIN32_FIND_DATAW ffd;
    HANDLE hFind = INVALID_HANDLE_VALUE;
    std::wstring searchPath = sourcePath + L"\\*";
    
    printf("\nScanning directory: %ls\n", sourcePath.c_str());
    printf("search path %ls\n", searchPath.c_str());
    
    hFind = FindFirstFileW(searchPath.c_str(), &ffd);
    if (hFind == INVALID_HANDLE_VALUE) {
        printf("FindFirstFile failed for %ls. Error: %lu\n", searchPath.c_str(), GetLastError());
        return;
    }

    do {
        if (wcscmp(ffd.cFileName, L".") == 0 || wcscmp(ffd.cFileName, L"..") == 0) {
            continue;
        }

        std::wstring srcPath = sourcePath + L"\\" + ffd.cFileName;
        std::wstring dstPath = destinationPath + L"\\" + ffd.cFileName;

        printf("Processing: %ls\n", srcPath.c_str());

        if (ffd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) {
            printf("Found directory: %ls\n", ffd.cFileName);
            
            // Create destination directory if it doesn't exist
            if (!CreateDirectoryW(dstPath.c_str(), NULL) && GetLastError() != ERROR_ALREADY_EXISTS) {
                printf("Failed to create directory %ls. Error: %lu\n", dstPath.c_str(), GetLastError());
                continue;
            }
            
            // Recursive call for subdirectories
            copyAndReplaceFiles(srcPath, dstPath);
        }
        else {
            printf("Replacing file: %ls -> %ls\n", srcPath.c_str(), dstPath.c_str());
            
            // Set normal attributes for destination file if it exists
            SetFileAttributesW(dstPath.c_str(), FILE_ATTRIBUTE_NORMAL);
            if (!ReplaceFileW(dstPath.c_str(), srcPath.c_str(), NULL,
                REPLACEFILE_IGNORE_MERGE_ERRORS, NULL, NULL)) {
                printf("Failed to replace file. Error: %lu\n", GetLastError());
            }
        }
    } while (FindNextFileW(hFind, &ffd) != 0);

    DWORD dwError = GetLastError();
    if (dwError != ERROR_NO_MORE_FILES) {
        printf("FindNextFile error. Error: %lu\n", dwError);
    }

    FindClose(hFind);
}

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

    printf("Copying new version\n");

    // Replace the existing copyDirectory lambda with copyAndReplaceFiles function
    std::wstring updateDir = L"update";
    std::wstring destDir = L".";

    copyAndReplaceFiles(updateDir, destDir);

    // Verify that the new executable exists
    if (!PathFileExistsW(executable_path))
    {
      printf("New executable does not exist at path: %ls\n", executable_path);
      ExitProcess(1);
    }
    else
    {
      printf("New executable found at path: %ls\n", executable_path);
    }

    printf("Starting new version\n");

    STARTUPINFOW si;
    PROCESS_INFORMATION pi;
    ZeroMemory(&si, sizeof(si));
    si.cb = sizeof(si);
    ZeroMemory(&pi, sizeof(pi));

    // Set execute permissions
    SetFileAttributesW(executable_path, FILE_ATTRIBUTE_NORMAL);

    BOOL processResult = CreateProcessW(
        executable_path, // Application name
        NULL,            // Command line
        NULL,            // Process handle not inheritable
        NULL,            // Thread handle not inheritable
        FALSE,           // Set handle inheritance to FALSE
        0,               // No creation flags
        NULL,            // Use parent's environment block
        NULL,            // Use parent's starting directory
        &si,             // Pointer to STARTUPINFO structure
        &pi              // Pointer to PROCESS_INFORMATION structure
    );

    if (processResult)
    {
      printf("Successfully started new process.\n");
      CloseHandle(pi.hProcess);
      CloseHandle(pi.hThread);
    }
    else
    {
      DWORD dwError = GetLastError();
      printf("Failed to start new process. Error: %lu\n", dwError);
    }

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
      struct LANGANDCODEPAGE
      {
        WORD wLanguage;
        WORD wCodePage;
      } *lpTranslate;

      UINT cbTranslate = 0;
      if (!VerQueryValueW(verData.data(), L"\\VarFileInfo\\Translation",
                          (LPVOID *)&lpTranslate, &cbTranslate) ||
          cbTranslate < sizeof(LANGANDCODEPAGE))
      {
        result->Error("VersionError", "Unable to get translation info.");
        return;
      }

      // Build the query string using the first translation
      wchar_t subBlock[50];
      swprintf(subBlock, 50, L"\\StringFileInfo\\%04x%04x\\ProductVersion",
               lpTranslate[0].wLanguage, lpTranslate[0].wCodePage);

      if (!VerQueryValueW(verData.data(), subBlock, (LPVOID *)&lpBuffer, &size))
      {
        result->Error("VersionError", "Unable to query version value.");
        return;
      }

      std::wstring productVersion((wchar_t *)lpBuffer);
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
