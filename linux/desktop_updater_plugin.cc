#include "include/desktop_updater/desktop_updater_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <sys/utsname.h>
#include <unistd.h>
#include <sys/wait.h>
#include <sys/stat.h>

#include <cstring>

#include "desktop_updater_plugin_private.h"

// Function to copy file from source to destination
bool copy_file(const char *source, const char *destination)
{
  char buffer[4096];
  size_t size;

  FILE *source_file = fopen(source, "rb");
  FILE *dest_file = fopen(destination, "wb");

  if (source_file == nullptr || dest_file == nullptr)
  {
    if (source_file)
      fclose(source_file);
    if (dest_file)
      fclose(dest_file);
    return false;
  }

  while ((size = fread(buffer, 1, sizeof(buffer), source_file)))
  {
    fwrite(buffer, 1, size, dest_file);
  }

  fclose(source_file);
  fclose(dest_file);
  return true;
}

#define DESKTOP_UPDATER_PLUGIN(obj)                                     \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), desktop_updater_plugin_get_type(), \
                              DesktopUpdaterPlugin))

struct _DesktopUpdaterPlugin
{
  GObject parent_instance;
};

G_DEFINE_TYPE(DesktopUpdaterPlugin, desktop_updater_plugin, g_object_get_type())

// Called when a method call is received from Flutter.
static void desktop_updater_plugin_handle_method_call(
    DesktopUpdaterPlugin *self,
    FlMethodCall *method_call)
{
  g_autoptr(FlMethodResponse) response = nullptr;

  const gchar *method = fl_method_call_get_name(method_call);

  if (strcmp(method, "getPlatformVersion") == 0)
  {
    response = get_platform_version();
  }
  else if (strcmp(method, "restartApp") == 0)
  {
    char executable_path[PATH_MAX];
    ssize_t len = readlink("/proc/self/exe", executable_path, sizeof(executable_path) - 1);
    if (len != -1)
    {
      executable_path[len] = '\0';

      // print executable_path
      g_print("executable_path: %s\n", executable_path);

      // Child process
      char backup_path[PATH_MAX];
      char replace_path[PATH_MAX];
      snprintf(backup_path, sizeof(backup_path), "%s.backup", executable_path);
      snprintf(replace_path, sizeof(replace_path), "%s.replace", executable_path);

      // Copy new version, replace path -> execatable path
      // copy_file(executable_path, replace_path);

      // Remove existing backup if exists
      remove(backup_path);

      // Rename current to backup
      rename(executable_path, backup_path);

      printf("Starting new version\n");

      // Copy new version, replace path -> execatable path
      copy_file(replace_path, executable_path);

      // Set permissions
      chmod(executable_path, 0755);

      // Start new version
      execl(executable_path, executable_path, NULL);

      _exit(0);
    }
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  }
  else
  {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

FlMethodResponse *get_platform_version()
{
  struct utsname uname_data = {};
  uname(&uname_data);
  g_autofree gchar *version = g_strdup_printf("Linux %s", uname_data.version);
  g_autoptr(FlValue) result = fl_value_new_string(version);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

static void desktop_updater_plugin_dispose(GObject *object)
{
  G_OBJECT_CLASS(desktop_updater_plugin_parent_class)->dispose(object);
}

static void desktop_updater_plugin_class_init(DesktopUpdaterPluginClass *klass)
{
  G_OBJECT_CLASS(klass)->dispose = desktop_updater_plugin_dispose;
}

static void desktop_updater_plugin_init(DesktopUpdaterPlugin *self) {}

static void method_call_cb(FlMethodChannel *channel, FlMethodCall *method_call,
                           gpointer user_data)
{
  DesktopUpdaterPlugin *plugin = DESKTOP_UPDATER_PLUGIN(user_data);
  desktop_updater_plugin_handle_method_call(plugin, method_call);
}

void desktop_updater_plugin_register_with_registrar(FlPluginRegistrar *registrar)
{
  DesktopUpdaterPlugin *plugin = DESKTOP_UPDATER_PLUGIN(
      g_object_new(desktop_updater_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            "desktop_updater",
                            FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, method_call_cb,
                                            g_object_ref(plugin),
                                            g_object_unref);

  g_object_unref(plugin);
}
