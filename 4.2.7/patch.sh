# predefined console font color/style
RED='\033[1;41;37m'
BLU='\033[1;94m'
YLW='\033[1;33m'
STD='\033[0m'
BLD='\033[1;97m'

# check whether user is root or superuser or sudoer
if [ $(id -u) -ne 0 ]; then
  # check whether user is sudoer or not
  NOT_SUDOER=$(sudo -l -U $USER 2>&1 | egrep -c -i "not allowed to run sudo|unknown user")
  if [ "$NOT_SUDOER" -ne 0 ]; then
    printf "\n"
    printf "${BLD}Please run this script as root (superadmin) or sudoer.${STD}\n"
    printf "This script requires super admin or sudoer.\n"
    printf "\n"
    exit
  fi
fi

# check internet connection
if ! ping -q -c 1 -W 1 github.com > /dev/null; then
  echo ""
  echo -e "${BLD}No internet connection detected.${STD}"
  echo -e "This installation script requires internet connection to download required patch."
  echo -e "Please set proper network and internet connection on this server before proceed."
  echo ""
  exit
fi

if ! which curl &> /dev/null; then
  echo ""
  echo -e "Please install ${BLD}curl${STD} required for this patch."
  echo ""
  exit
fi

PROGRAM_LOCATION="/srv/www/htdocs/orangeapigw"
VERSION_FILE="${PROGRAM_LOCATION}/version.properties"
FILE_TO_PATCH="${PROGRAM_LOCATION}/file/index.php"
FILE_BAK="${PROGRAM_LOCATION}/file/index.bak"

if [ ! -d "${PROGRAM_LOCATION}" ]; then
  echo ""
  echo "Standar program location:"
  echo -e "${BLD}${PROGRAM_LOCATION}${STD}"
  echo "is not found, or moved"
  echo "this online patch can not be used"
  echo ""
  exit
fi

if [ ! -f "${VERSION_FILE}" ]; then
  echo ""
  echo "Version file:"
  echo -e "${BLD}${VERSION_FILE}${STD}"
  echo "is not found, or moved"
  echo "this online patch can not be used"
  echo ""
  exit
fi

if [ ! -f "${FILE_TO_PATCH}" ]; then
  echo ""
  echo "File to be patched:"
  echo -e "${BLD}${FILE_TO_PATCH}${STD}"
  echo "is not found, or moved"
  echo "this online patch can not be used"
  echo ""
  exit
fi

if [ -f "${FILE_BAK}" ]; then
  echo ""
  echo "Backup file:"
  echo -e "${BLD}${FILE_BAK}${STD}"
  echo "already exists, patch may have been done"
  echo "this online patch can not be used"
  echo ""
  exit
fi

# Default values
IS_SUDOER=0
IS_ROOT=0

# Check if the current user is root
if [ "$(id -u)" -eq 0 ]; then
  IS_ROOT=1
fi

# Check if the current user is a sudoer
if sudo -n true 2>/dev/null; then
  IS_SUDOER=1
fi

version="unknown"

source "${VERSION_FILE}"

if [ "$version" != "4.2.7" ]; then
  echo ""
  echo -e "This patch is specific for version ${BLD}4.2.7${STD} only"
  echo "This OrangE API Gateway version is:"
  echo -e "${BLD}${version}${STD}"
  echo ""
  exit
fi

# Get the original file's owner and permissions
OWNER=$(stat -c '%u:%g' "${FILE_TO_PATCH}")
PERMISSION=$(stat -c '%a' "${FILE_TO_PATCH}")

if [ "${IS_SUDOER}" -eq 1 ]; then
  sudo mv "${FILE_TO_PATCH}" "${FILE_BAK}"
else
  mv "${FILE_TO_PATCH}" "${FILE_BAK}"
fi

if [ "$?" -ne 0 ]; then
  echo ""
  echo "Failed to create backup file:"
  echo -e "${BLD}${FILE_BAK}${STD}"
  echo -e "Patch is failed"
  echo ""
  exit
fi

UPDATE_URL="https://raw.githubusercontent.com/myspsolution/orangeapigw-patch/main/4.2.7/file/index.php"

if [ "${IS_SUDOER}" -eq 1 ]; then
  sudo curl -kSs -o "${FILE_TO_PATCH}" "${UPDATE_URL}"
else
  curl -kSs -o "${FILE_TO_PATCH}" "${UPDATE_URL}"
fi

if [ "$?" -ne 0 ]; then
  if [ "${IS_SUDOER}" -eq 1 ]; then
  sudo rm -f "${FILE_TO_PATCH}"
    sudo mv "${FILE_BAK}" "${FILE_TO_PATCH}"
  else
    rm -f "${FILE_TO_PATCH}"
    mv "${FILE_BAK}" "${FILE_TO_PATCH}"
  fi

  echo ""
  echo "Failed to download file:"
  echo -e "${BLD}${UPDATE_URL}${STD}"
  echo -e "Patch is failed, the original is restored"
  echo ""
  exit
fi

if [ "${IS_SUDOER}" -eq 1 ]; then
  sudo chown "${OWNER}" "${FILE_TO_PATCH}"
  sudo chmod "${PERMISSION}" "${FILE_TO_PATCH}"
  sudo sed -i 's/^version=4\.2\.7$/version=4.2.8/' "${VERSION_FILE}"
else
  chown "${OWNER}" "${FILE_TO_PATCH}"
  chmod "${PERMISSION}" "${FILE_TO_PATCH}"
  sed -i 's/^version=4\.2\.7$/version=4.2.8/' "${VERSION_FILE}"
fi

echo ""
echo "Orange API Gateway is successfully patched to version:"
echo -e "${BLD}4.2.8${STD}"
echo ""
