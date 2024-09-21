#ifndef FLUTTER_PLUGIN_zikzak_share_handler_LINUX_H_
#define FLUTTER_PLUGIN_zikzak_share_handler_LINUX_H_

#include <flutter_linux/flutter_linux.h>

G_BEGIN_DECLS

#ifdef FLUTTER_PLUGIN_IMPL
#define FLUTTER_PLUGIN_EXPORT __attribute__((visibility("default")))
#else
#define FLUTTER_PLUGIN_EXPORT
#endif

typedef struct _ShareHandlerLinuxPlatform ShareHandlerLinuxPlatform;
typedef struct {
  GObjectClass parent_class;
} ShareHandlerLinuxPlatformClass;

FLUTTER_PLUGIN_EXPORT GType zikzak_share_handler_linux_get_type();

FLUTTER_PLUGIN_EXPORT void zikzak_share_handler_linux_register_with_registrar(
    FlPluginRegistrar* registrar);

G_END_DECLS

#endif  // FLUTTER_PLUGIN_zikzak_share_handler_LINUX_H_
