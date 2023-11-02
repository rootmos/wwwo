import importlib.metadata

package_name = __name__
package_version = importlib.metadata.version(package_name)

app_name = __name__.replace("_", "-")
env_prefix = package_name.upper() + "_"
