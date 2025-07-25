validate_preinst() {
  # use install_log to write to installer log file.
  install_log "validate_preinst ${SYNOPKG_PKG_STATUS}"
}

validate_preuninst() {
  # use install_log to write to installer log file.
  install_log "validate_preuninst ${SYNOPKG_PKG_STATUS}"
}

validate_preupgrade() {
  # use install_log to write to installer log file.
  install_log "validate_preupgrade ${SYNOPKG_PKG_STATUS}"
}

service_preinst() {
  # use echo to write to the installer log file.
  echo "service_preinst ${SYNOPKG_PKG_STATUS}"
}

service_postinst() {
  # use echo to write to the installer log file.
  echo "service_postinst ${SYNOPKG_PKG_STATUS}"
}

service_preuninst() {
  # use echo to write to the installer log file.
  echo "service_preuninst ${SYNOPKG_PKG_STATUS}"
}

service_postuninst() {
  # use echo to write to the installer log file.
  echo "service_postuninst ${SYNOPKG_PKG_STATUS}"
}

service_preupgrade() {
  # use echo to write to the installer log file.
  echo "service_preupgrade ${SYNOPKG_PKG_STATUS}"
}

service_postupgrade() {
  # use echo to write to the installer log file.
  echo "service_postupgrade ${SYNOPKG_PKG_STATUS}"
}

# REMARKS:
# installer variables are not available in the context of service start/stop
# The regular solution is to use configuration files for services

service_prestart() {
  # use echo to write to the service log file.
  echo "service_prestart: Before service start"

  LUR_PATH="${SYNOPKG_PKGDEST}/udev"
  LFW_PATH="${SYNOPKG_PKGDEST}/firmware"

  _release=$(/bin/uname -r)
  KVER="$(/bin/echo ${_release%%[-+]*} | /usr/bin/cut -d'.' -f1-3)"
  PLATFORM=$(get_key_value /etc/synoinfo.conf platform_name)
  if [ "$(echo "${KVER:-4}" | cut -d'.' -f1)" -lt 5 ]; then
    KPRE=""
  else
    majorversion="$(/bin/get_key_value /etc/VERSION majorversion)"
    minorversion="$(/bin/get_key_value /etc/VERSION minorversion)"
    KPRE="${majorversion}.${minorversion}"
  fi
  LMK_PATH="${SYNOPKG_PKGDEST}/modules/${PLATFORM}-${KPRE:+${KPRE}-}${KVER}"

  # Add udev rules to system
  HAS_RULES=false
  for R in ${LUR_PATH}/rules.d/*.rules; do
    [ -e "${R}" ] || continue
    RN="$(basename "${R}")"
    [ -e "/lib/udev/rules.d/${RN}" ] && continue
    ln -s "${LUR_PATH}/rules.d/${RN}" "/lib/udev/rules.d/${RN}"
    HAS_RULES=true
  done
  if [ "${HAS_RULES}" = true ]; then
    for S in ${LUR_PATH}/script/*.sh; do
      [ -e "${S}" ] || continue
      SN="$(basename "${S}")"
      [ -e "/lib/udev/script/${SN}" ] && continue
      ln -s "${LUR_PATH}/script/${SN}" "/lib/udev/script/${SN}"
    done
    echo "Reloading udev rules..."
    udevadm control --reload-rules
    udevadm trigger
  fi

  # Add firmware path to running kernel
  SYS_LFW_PATH="/sys/module/firmware_class/parameters/path" # System module firmware path file index
  grep -q "${LFW_PATH}" "${SYS_LFW_PATH}" || echo "${LFW_PATH}" >>"${SYS_LFW_PATH}"

  # install kernel modules
  for M in mii.ko usbnet.ko; do
    for P in "${LMK_PATH}" "/usr/lib/modules"; do
      /sbin/lsmod | grep -wq "^$(echo "${M}" | sed 's/-/_/')" && break || /sbin/insmod "${P}/${M}.ko" 2>/dev/null
    done
  done

  /sbin/lsmod | grep -wq "^r8152" && /sbin/rmmod -f r8152
  /sbin/insmod "${LMK_PATH}/r8152.ko"
}

service_poststop() {
  # use echo to write to the service log file.
  echo "service_poststop: After service stop"

  LUR_PATH="${SYNOPKG_PKGDEST}/udev"
  LFW_PATH="${SYNOPKG_PKGDEST}/firmware"

  _release=$(/bin/uname -r)
  KVER="$(/bin/echo ${_release%%[-+]*} | /usr/bin/cut -d'.' -f1-3)"
  PLATFORM=$(get_key_value /etc/synoinfo.conf platform_name)
  if [ "$(echo "${KVER:-4}" | cut -d'.' -f1)" -lt 5 ]; then
    KPRE=""
  else
    majorversion="$(/bin/get_key_value /etc/VERSION majorversion)"
    minorversion="$(/bin/get_key_value /etc/VERSION minorversion)"
    KPRE="${majorversion}.${minorversion}"
  fi
  LMK_PATH="${SYNOPKG_PKGDEST}/modules/${PLATFORM}-${KPRE:+${KPRE}-}${KVER}"

  # Remove udev rules from system
  HAS_RULES=false
  for R in ${LUR_PATH}/rules.d/*.rules; do
    [ -e "${R}" ] || continue
    RN="$(basename "${R}")"
    [ -L "/lib/udev/rules.d/${RN}" ] || continue
    rm -f "/lib/udev/rules.d/${RN}"
    HAS_RULES=true
  done
  if [ "${HAS_RULES}" = true ]; then
    if [ ! -L "/lib/udev/rules.d/99-usb-netcard.rules" ] && [ -L "/lib/udev/script/usb-netcard.sh" ]; then
      rm -f "/lib/udev/script/usb-netcard.sh"
    fi
    echo "Reloading udev rules..."
    udevadm control --reload-rules
    udevadm trigger
  fi

  # Remove firmware path from running kernel
  SYS_LFW_PATH="/sys/module/firmware_class/parameters/path" # System module
  sed -i "/${LFW_PATH}/d" "${SYS_LFW_PATH}" || true

  # Remove kernel modules
  for M in mii.ko usbnet.ko; do
    /sbin/lsmod | grep -wq "^$(echo "${M}" | sed 's/-/_/')" && /sbin/rmmod "${M}" || true
  done
  /sbin/lsmod | grep -wq "^r8152" && /sbin/rmmod -f r8152 || true
}
