#!/bin/bash -e

# These are constants and should not be touched
dir_aur='aur'
dir_pkg='pkg'
dir_uboot='uboot'
dir_booting='booting'
dir_releases='releases'

no_root() {
  echo " => Checking if running with root permission..."
  if [[ "${UID}" == 0 ]]; then
    echo "  -> Error: running with root permission, refuse to build for safety concerns"
    return 1
  fi
  echo " => No root permission, check pass"
}

no_makepkg_conf() {
  local makepkg_conf='/etc/makepkg.conf'
  echo " => Checking ${makepkg_conf}..."
  local conf=$(
    . ${makepkg_conf}
    echo "${PKGDEST}${SRCDEST}${SRCPKGDEST}"
  )
  if [[ "${conf}" ]]; then
    echo "  -> Error: either PKGDEST, SRCDEST or SRCPKGDEST is set in ${makepkg_conf}"
    return 1
  fi
  echo " => ${makepkg_conf} check pass"
}

prepare_uboot() {
  echo " => Preparing u-boot..."
  local uboot_names=(
    'e900v22c'
    'gtking'
    'gtkingpro'
    'gtkingpro-rev-a'
    'n1'
    'odroid-n2'
    'p201'
    'p212'
    'r3300l'
    's905'
    's905x2-s922'
    's905x-s912'
    'sei510'
    'sei610'
    'skyworth-lb2004'
    'tx3-bz'
    'tx3-qz'
    'u200'
    'ugoos-x3'
    'x96max'
    'x96maxplus'
    'zyxq'
  )
  local uboot_sha256sums=(
    'fb0d8e321828642bf2c930dae96fd0048933f87e4d4228a77270a4d1aa7e7b41'
    '7c0c91e60d107c61de03798fcb04e462c7e5616b400ee6abc096b94e97a2cee0'
    '215f2f3abbd03f19a7b304f5dd7824914a16d9bdecb0711845a8c2fa7e292483'
    'b8fc82e1a4a72ce15ee6fee8776ef26f9ae4834b641a2e4b6a912a3e89efdff6'
    '5094d8144688c5fc20424497afb11b04187c9efdf8adf95cd2a9fbbd951b8cfc'
    'e0e7a258e024aa8e825a6c46c68fdf0e6da2dfa54d379115b91fae25176e748f'
    '3a76dc9b2d80988ffbaade9555700b6d9121498eef6f75000ebd11e9f991ed3f'
    'c3b2065356e61cec05320e68010135a315e7d89d0e6d6dd212a55a28cf90f7e8'
    '27874155c05d4c8252cf443a78c84867d071960dff0d66dbee5c8f19a3d30737'
    'f69f6241224f72e6942119dae0d026154089cdff8442d5a4c93de4d8bc3e69b9'
    'c3a3662453cbbfcd7a11e2c829017b667e601708f2f5c85543f1727249787a74'
    '3becd7d97afaa7fbcb683eb4c28221f282bf73b74d71138ac6be768611f8e11f'
    '5ff0be52537bd01ab6aa772e0ee284ab1e1f47f43cbc08da2a6c9982ef1df379'
    'ddf6ff930c13c03528b64a738de1126f811f6802c5096495ef83f6c07c4986d1'
    'c2984db61bebf94c13a9d458cb77fdfb6b2a017516862fbbad159f8a480880d0'
    '3e89947c31bacc31574213f86ab03339291dcde928872dc6ae957fce58e76ac9'
    'aba80167498ef01482118c210636f14306ccaea80d09dce9e4358b993c0b3d88'
    '065370807a82019677cff7adaea917f1a08c5cc4baca4c5d9e19b117b66e5ce6'
    '4a33c8dc3acedd646f0676bb5c9a5b2718450fca6c5871949cb85fa244321bc1'
    'e23bc57cefb1b99ecfb7a4192e8960c9b2a44f75d902ad6ff007108f9e01cc7b'
    '2bc15470d83f9e4e748f62897a0b3f71f896da51bf41591a03eebc289ee703dc'
    '3df7343e56116244b2d2d2fa8bcdbf411c088667bfc850f163d3b0b8caca29aa'
  )
  local armbian_repo='https://github.com/ophub/amlogic-s9xxx-armbian'
  local armbian_commit='8d5f8a8ac2fb1a7b749a67274f44edd308ce7a6a'
  mkdir -p "${dir_uboot}"
  local uboot_name uboot_file uboot_sha256sum i=0
  local wget=${wget:-wget} # User can e.g. export wget='proxychains wget', so it can go through proxy
  for uboot_name in "${uboot_names[@]}"; do
    uboot_file="${dir_uboot}/${uboot_name}"
    if [[ -f "${uboot_file}" ]]; then
      sha256sum_log=$(sha256sum "${uboot_file}") # This is written as a single command without piping to cut because I want it to fail it sha256sum fails
      sha256sum_actual="${sha256sum_log::64}"
      sha256sum_expected="${uboot_sha256sums[$i]}"
      if [[ "${sha256sum_actual}" ==  "${sha256sum_expected}" ]]; then
        echo "  -> u-boot for ${uboot_name} already exists and sha256sum is correct, skip it"
        i=$(($i+1))
        continue
      else
        echo "  -> existing u-boot for ${uboot_name} has different sha256sum than expected, will re-downloadd"
        echo "   -> actual: ${sha256sum_actual}"
        echo "   -> expected: ${sha256sum_expected}"
        rm -f "${uboot_file}"
      fi
    fi
    # A URL should look like this: 
    # https://github.com/ophub/amlogic-s9xxx-armbian/blob/main/build-armbian/u-boot/amlogic/overload/u-boot-s905x-s912.bin
    ${wget} "${armbian_repo}/raw/${armbian_commit}/build-armbian/u-boot/amlogic/overload/u-boot-${uboot_name}.bin" -O "${uboot_file}"
    sha256sum_log=$(sha256sum "${uboot_file}") # This is written as a single command without piping to cut because I want it to fail it sha256sum fails
    sha256sum_actual="${sha256sum_log::64}"
    sha256sum_expected="${uboot_sha256sums[$i]}"
    if [[ "${sha256sum_actual}" !=  "${sha256sum_expected}" ]]; then
      echo "  -> Error: u-boot for ${uboot_name} has different sha256sum"
      echo "   -> actual: ${sha256sum_actual}"
      echo "   -> expected: ${sha256sum_expected}"
      exit 1
    fi
    i=$(($i+1))
    echo "  -> u-boot for ${uboot_name} downloaded and checked correct"
  done
}

prepare_name() {
  echo " => Preparing name"
  local name_distro='ArchLinuxARM-aarch64-Amlogic'
  name_date=$(date +%Y%m%d_%H%M%S)
  name_base="${name_distro}-${name_date}"
  echo "  -> Basename ${name_base}"
  name_disk="${name_base}.img"
  name_disk_compressed="${name_disk}.xz"
  name_archive_root="${name_base}-root.tar"
  name_archive_root_compressed="${name_archive_root}.xz"
  name_archive_pkgs="${name_base}-pkgs.tar"
  name_archive_pkgs_compressed="${name_archive_pkgs}.xz"
  name_release_note="${name_base}.md"
  echo " => Name prepared"
}

should_build_aur() { 
  # should be called inside the folder
  # #1 aur name
  local aur_pkg=$1
  (
    . PKGBUILD
    file_blacklist="../${aur_pkg}.blacklist"
    file_whitelist="../${aur_pkg}.whitelist"
    if [[ -f "${file_blacklist}" ]]; then
      readarray -t blacklist < "${file_blacklist}"
    else
      blacklist=()
    fi
    if [[ -f "${file_whitelist}" ]]; then
      readarray -t whitelist < "${file_whitelist}"
    else
      whitelist=()
    fi
    pkgfiles=()
    for i in "${pkgname[@]}"; do
      if [[ "${blacklist}" ]]; then
        should_build='yes'
        for j in "${blacklist[@]}"; do
          if [[ "${j}" == "${i}" ]]; then
            should_build=''
            break
          fi
        done
        if [[ -z "${should_build}" ]]; then
          continue
        fi
      fi
      if [[ "${whitelist}" ]]; then
        should_build=''
        for j in "${whitelist[@]}"; do
          if [[ "${j}" == "${i}" ]]; then
            should_build='yes'
            break
          fi
        done
        if [[ -z "${should_build}" ]]; then
          continue
        fi
      fi
      # if [[ $(type -t pkgver) == 'function' ]]; then
      #   pkgfile_glob1="${i}-"
      #   pkgfile_glob2="-${pkgrel}-aarch64${PKGEXT}"
      #   pkgfile=
      #   compgen -G 
      #   pkgfilename=($(compgen -G "${pkgfile_glob1}"*"${pkgfile_glob2}")) # Will only use the first one
      # else
      pkgfilename="${i}-${pkgver}-${pkgrel}-aarch64${PKGEXT}"
      pkgfile="${dir_pkg_absolute}/${pkgfilename}"
      # pkgfilenames+=(${pkgfilename})
      if [[ -f "${pkgfile}" ]]; then
        pkgfiles+=("${pkgfile}")
      else
        echo "  -> ${pkgfilename} provided by ${1} not found in built packages, should build ${1}"
        exit 0
      fi
      # fi
    done
    for pkgfile in "${pkgfiles[@]}"; do
      chmod -x "${pkgfile}"
    done
    echo "  -> All package files existing for ${1}, can be skipped"
    exit 1
  )
  return $?
}

move_built_to_pkg() {
  # should be called inside the folder
  # #1 aur name
  # #2 dir_pkg_absolute
  local aur_pkg="$1"
  local dir_pkg_absolute="$2"
  (
    . PKGBUILD
    file_blacklist="../${aur_pkg}.blacklist"
    file_whitelist="../${aur_pkg}.whitelist"
    if [[ -f "${file_blacklist}" ]]; then
      readarray -t blacklist < "${file_blacklist}"
    else
      blacklist=()
    fi
    if [[ -f "${file_whitelist}" ]]; then
      readarray -t whitelist < "${file_whitelist}"
    else
      whitelist=()
    fi
    for i in "${pkgname[@]}"; do
      if [[ "${blacklist}" ]]; then
        should_build='yes'
        for j in "${blacklist[@]}"; do
          if [[ "${j}" == "${i}" ]]; then
            should_build=''
            break
          fi
        done
        if [[ -z "${should_build}" ]]; then
          continue
        fi
      fi
      if [[ "${whitelist}" ]]; then
        should_build=''
        for j in "${whitelist[@]}"; do
          if [[ "${j}" == "${i}" ]]; then
            should_build='yes'
            break
          fi
        done
        if [[ -z "${should_build}" ]]; then
          continue
        fi
      fi
      if [[ $(type -t pkgver) == 'function' ]]; then
        pkgfile_glob1="${i}-"
        pkgfile_glob2="-${pkgrel}-aarch64${PKGEXT}"
        chmod -x "${pkgfile_glob1}"*"${pkgfile_glob2}"
        mv -vf "${pkgfile_glob1}"*"${pkgfile_glob2}" "${dir_pkg_absolute}/"
      else
        pkgfile="${i}-${pkgver}-${pkgrel}-aarch64${PKGEXT}"
        chmod -x "${pkgfile}"
        mv -vf "${pkgfile}" "${dir_pkg_absolute}/"
      fi
    done
  )
}

prepare_aur() {
  echo " => Preparing AUR packages..."
  echo "  -> Updateing submodules..."
  git submodule update --remote
  echo "  -> Cleaning AUR build dir..."
  find "${dir_aur}" -maxdepth 2 -name '*-aarch64.pkg.tar' -exec rm -rf {} \;
  echo "  -> Preparing package storage dir..."
  mkdir -p "${dir_pkg}"
  if compgen -G "${dir_pkg}/"* &>/dev/null && ! chmod u+x "${dir_pkg}/"*; then
    # We use executable permission to do two things:
    #  1. The user must be the owner of the file to run chmod u+x, so this bails out if it is not owned by the user
    #  2. We use it as a pseudo un-check flag, after checking the x permission will be removed from a file, so we
    #     can just remove all of the files that's still executable
    echo "  -> Failed to mark all existing package files are executable to use as check flag"
    exit 1
  fi
  local dir_pkg_absolute=$(readlink -f "${dir_pkg}")
  local PKGEXT=.pkg.tar
  export PKGEXT
  pushd "${dir_aur}"
  for aur_pkg in *; do
    if [[ ! -d "${aur_pkg}" ]]; then
      continue
    fi
    pushd "${aur_pkg}"
    if should_build_aur "${aur_pkg}"; then
      echo "  -> Building AUR package ${aur_pkg}..."
      local retry=3
      local success=''
      while [[ ${retry} -ge 0 ]]; do
        makepkg -cfsAC
        if [[ $? == 0 ]]; then
          success='yes'
          break
        fi
        echo "  -> Retrying to build AUR package ${aur_pkg}, retries left: ${retry}"
      done
      if [[ -z "${success}" ]]; then
        echo "  -> Failed to build AUR package ${aur_pkg} after 3 retries"
        exit 1
      fi
      move_built_to_pkg "${aur_pkg}" "${dir_pkg_absolute}"
    fi
    popd
  done
  popd
  local i
  for i in "${dir_pkg}/"*; do
    if [[ -x "${i}" ]]; then
      rm -f "${i}"
    fi
  done
  echo " => AUR packages prepared"
}

prepare_uuid() {
  echo " => Preparing UUID..."
  uuid_root=$(uuidgen)
  uuid_boot_mkfs=$(uuidgen)
  uuid_boot_mkfs=${uuid_boot_mkfs::8}
  uuid_boot_mkfs=${uuid_boot_mkfs^^}
  uuid_boot_specifier="${uuid_boot_mkfs::4}-${uuid_boot_mkfs:4}"
  echo "  -> UUID for root partition is ${uuid_root}"
  echo "  -> UUID for boot partition is ${uuid_boot_mkfs} / ${uuid_boot_specifier}"
  echo " => UUID prepared"
}

create_disk() {
  echo " => Creating disk..."
  local size_split=256M
  local size_disk=2G
  mkdir -p "${dir_releases}"
  path_disk="${dir_releases}/${name_disk}"
  echo "  -> Disk path is ${path_disk}"
  rm -f "${path_disk}"
  echo "  -> Allocating disk space..."
  truncate -s "${size_disk}" "${path_disk}"
  echo "  -> Creating partition table..."
  parted -s "${path_disk}" \
    mklabel msdos \
    mkpart primary fat32 1MiB "${size_split}iB" \
    mkpart primary "${size_split}iB" 100%
  echo ' => Disk created'
}

setup_loop() {
  echo " => Setting up loop device..."
  loop_disk=$(sudo losetup -fP --show "${path_disk}")
  echo "  -> Using loop device ${loop_disk}"
  loop_boot="${loop_disk}p1"
  loop_root="${loop_disk}p2"
  echo " => Set up loop device"
}

create_fs() {
  echo " => Creating FS..."
  echo "  -> Creating FAT32 FS with UUID ${uuid_boot_mkfs} on ${loop_boot}"
  sudo mkfs.vfat -n 'ALARMBOOT' -F 32 -i "${uuid_boot_mkfs}" "${loop_boot}"
  echo "  -> Creating ext4 FS with UUID ${uuid_root} on ${loop_root}"
  sudo mkfs.ext4 -L 'ALARMROOT' -m 0 -U "${uuid_root}" "${loop_root}"
  echo " => Created FS"
}

create_mountpoint() {
  echo " => Creating mountpoint..."
  dir_root=$(sudo mktemp -d)
  echo "  -> Using ${dir_root} as mountpoint"
  dir_boot="${dir_root}/boot"
  echo " => Created mountpoint"
}

mount_tree() {
  echo " => Mounting root tree"
  echo "  -> Mounting ${loop_root} to ${dir_root}"
  sudo mount -o noatime "${loop_root}" "${dir_root}"
  sudo mkdir -p "${dir_boot}"
  echo "  -> Mounting ${loop_boot} to ${dir_boot}"
  sudo mount -o noatime "${loop_boot}" "${dir_boot}"
  echo " => Root tree mounted"
}

pacstrap_base() {
  echo " => Pacstrapping the base package group and other packages from official repo into ${dir_root}..."
  echo "  -> openssh: for remote management"
  echo "  -> vim: for text editting"
  echo "  -> sudo: for privilege elevation"
  sudo pacstrap "${dir_root}" base openssh vim sudo
  echo " => Pacstrap base done"
}

pacstrap_aur() {
  echo " => Pacstrapping the AUR packages into ${dir_root}..."
  local pkg_suffix='aarch64.pkg.tar'
  # local pkg_names=(
  #   'ampart-git'
  #   'linux-aarch64-flippy-dtb-amlogic'
  #   'linux-firmware-amlogic-ophub'
  #   'uboot-legacy-initrd-hooks'
  #   'yay'
  # )
  # local pkg_name pkg_match
  # local pkgs=()
  # for pkg_name in "${pkg_names[@]}"; do
  #   pkg_match=("${dir_pkg}/${pkg_name}-"*"-${pkg_suffix}")
  #   if [[ "${#pkg_match[@]}" != 1 ]]; then
  #     echo "  -> Error: not exact one match for package ${pkg_name}, matches: ${pkg_match[@]}"
  #     return 1
  #   fi
  #   pkgs+=(${pkg_match[0]})
  # done
  # if [[ ${#pkgs[@]} != 5 ]]; then
  #   echo "  -> Error: Not all 5 of ${pkg_names[@]} are found"
  #   return 2
  # fi
  # local pkg
  # for pkg in "${dir_pkg}/linux-aarch64-flippy-"*"-${pkg_suffix}"; do
  #   pkg_name="$(basename "${pkg}")"
  #   case "$pkg_name" in
  #     linux-aarch64-flippy-dtb-*) :;;
  #     linux-aarch64-flippy-headers-*) :;;
  #     *)
  #       pkgs+=("${pkg}")
  #       break
  #     ;;
  #   esac
  # done
  # if [[ ${#pkgs[@]} != 6 ]]; then
  #   echo "  -> Error: Package linux-aarch64-flippy-bin was not found"
  #   return 3
  # fi
  sudo pacstrap -U "${dir_root}" "${dir_pkg}/"*
  echo " => Pacstrap AUR done"
}

genfstab_root() {
  echo " => Generating fstab..."
  local fstab_file="${dir_root}/etc/fstab"
  local fstab_content=$(
    printf '# root partition with ext4 on SDcard / USB drive\nUUID=%s\t/\text4\trw,noatime,data=writeback\t0 1\n# boot partition with vfat on SDcard / USB drive\nUUID=%s\t/boot\tvfat\trw,noatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,utf8,errors=remount-ro\t0 2\n' "${uuid_root}" "${uuid_boot_specifier}"
  )
  local fstab_cache=$(mktemp)
  echo "${fstab_content}" > "${fstab_cache}"
  sudo cp "${fstab_cache}" "${fstab_file}"
  rm -f "${fstab_cache}"
  echo " => Generated fstab"
}

populate_boot() {
  echo " => Populating boot partition..."
  echo "  -> Writing booting scripts..."
  local script name
  for script in booting/*.sh; do
    name=$(basename "$script")
    if [ "${name}" == 'boot.sh' ]; then
      name="${name%.sh}.scr"
    else
      name="${name%.sh}"
    fi
    sudo mkimage -A arm64 -O linux -T script -C none -d "${script}" "${dir_boot}/${name}" > /dev/null
  done
  echo "  -> Writing booting configuration..."
  local kernel='linux-aarch64-flippy'
  local conf_linux="vmlinuz-${kernel}"
  local conf_initrd="initramfs-${kernel}-fallback.uimg"
  local conf_fdt="dtbs/${kernel}/amlogic/PLEASE_SET_YOUR_DTB.dtb"
  local conf_append="root=UUID=${uuid_root} rootflags=data=writeback rw rootfstype=ext4 console=ttyAML0,115200n8 console=tty0 no_console_suspend consoleblank=0 fsck.fix=yes fsck.repair=yes net.ifnames=0 cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory swapaccount=1"
  local subst="
    s|%LINUX%|${conf_linux}|g
    s|%INITRD%|${conf_initrd}|g
    s|%FDT%|${conf_fdt}|g
    s|%APPEND%|${conf_append}|g
  "
  local temp_uenv=$(mktemp)
  local temp_extlinux=$(mktemp)
  sed "${subst}" "${dir_booting}/uEnv.txt" > "${temp_uenv}"
  sed "${subst}" "${dir_booting}/extlinux.conf" > "${temp_extlinux}"
  sudo cp "${temp_uenv}" "${dir_boot}/uEnv.txt"
  sudo mkdir -p "${dir_boot}/extlinux"
  sudo cp "${temp_extlinux}" "${dir_boot}/extlinux/extlinux.conf"
  rm -f "${temp_uenv}" "${temp_extlinux}"
  echo "  -> Dumping uboot..."
  sudo cp -rv "${dir_uboot}" "${dir_boot}/"
  echo " => Populated boot partition"
}

sanity_check() {
  echo "=> Sanity checking..."
  no_root
  no_makepkg_conf
  echo "=> Sanity check end"
}

prepare() {
  echo "=> Preparing..."
  prepare_uboot
  prepare_aur
  prepare_name
  prepare_uuid
  echo "=> Preparation end"
}

deploy() {
  echo "=> Deploying..."
  create_disk
  setup_loop
  create_fs
  create_mountpoint
  mount_tree
  pacstrap_base
  genfstab_root
  pacstrap_aur
  populate_boot
  echo "=> Deploy end"
}

basic_setup() {
  echo " => Basic setup outside the target root"
  echo "  -> Setting timezone to Asia/Shanghai"
  sudo ln -sf /usr/share/zoneinfo/Asia/Shanghai "${dir_root}/etc/localtime"
  echo "  -> Enabling locales en_US.UTF-8, en_GB.UTF-8, zh_CN.UTF-8"
  local locale_zh='zh_CN.UTF-8 UTF-8'
  local locale_gb='en_GB.UTF-8 UTF-8'
  local locale_us='en_US.UTF-8 UTF-8'
  sudo sed -i "
    s|^#${locale_zh}  $|${locale_zh}  |g
    s|^#${locale_gb}  $|${locale_gb}  |g
    s|^#${locale_us}  $|${locale_us}  |g
  " "${dir_root}/etc/locale.gen"
  echo "  -> Setting en_GB.UTF-8 as locale"
  echo 'LANG=en_GB.UTF-8' | sudo tee "${dir_root}/etc/locale.conf"
  echo "  -> Setting hostname to alarm"
  echo 'alarm' | sudo tee "${dir_root}/etc/hostname"
  echo "  -> Setting basic localhost"
  printf '127.0.0.1\tlocalhost\n::1\t\tlocalhost\n' | sudo tee -a "${dir_root}/etc/hosts"
  echo "  -> Setting DHCP on eth* with systemd-networkd"
  printf '[Match]\nName=eth* en*\n\n[Network]\nDHCP=yes\nDNSSEC=no\n' | sudo tee "${dir_root}/etc/systemd/network/20-wired.network"
  echo "  -> Creating symbol link /etc/resolve.conf => /run/systemd/resolve/resolv.conf in case systemd-resolved fails to set it up"
  sudo ln -sf /run/systemd/resolve/resolv.conf "${dir_root}/etc/resolv.conf"
  echo "  -> Setting VIM as VI..."
  sudo ln -sf 'vim' "${dir_root}/usr/bin/vi"
  echo "  -> Setting up sudo, to allow users in group wheel to use sudo with password"
  local sudoers="${dir_root}/etc/sudoers"
  sudo chmod o+w "${sudoers}"
  sudo sed -i 's|^# %wheel ALL=(ALL:ALL) ALL$|%wheel ALL=(ALL:ALL) ALL|g' "${sudoers}"
  sudo chmod o-w "${sudoers}"
  echo '  -> Setting up SSH, to allow to login as root with password'
  sudo sed -i 's|^#PermitRootLogin prohibit-password$|PermitRootLogin yes|g' "${dir_root}/etc/ssh/sshd_config"
  echo " => Completed basic setup outside the target root"
}

run_inside() {
  echo "=> Getting into the target root"
  local script_name='inroot.sh'
  local script_in_path="/root/${script_name}"
  local script_actual_path="${dir_root}${script_in_path}"
  sudo install -Dm755 'inroot.sh' "${script_actual_path}"
  sudo arch-chroot "${dir_root}" "${script_in_path}"
  sudo rm -f "${script_actual_path}"
  echo "=> Getting out from the target root"
}

get_versions() {
  echo " => Getting package versions to be used in later release note"
  file_versions=$(mktemp)
  pacman -Q --root "${dir_root}" > "${file_versions}"
  echo " => Got version"
}

remove_non_fallback() {
  echo " => Removing non-fallback non-legacy initramfs..."
  sudo rm -f ${dir_boot}/initramfs-linux-aarch64-flippy.{u,}img ${dir_boot}/initramfs-linux-aarch64-flippy-fallback.img
  echo " => Removed non-fallback non-legacy initramfs"
}

clean_pacman() {
  echo " => Cleaning Pacman package cache..."
  sudo rm -rf "${dir_root}/var/cache/pacman/pkg/"*
  echo " => Pacman cache cleaned"
}

cleanup() {
  echo "=> Cleaning up..."  
  clean_pacman
  remove_non_fallback
  echo "=> Cleaned up"
}

make_archive_pkgs() {
  echo "=> Creating packages archive..."
  local path_archive="${dir_releases}/${name_archive_pkgs}"
  echo " -> Creating archive ${path_archive} without compression..."
  (
    cd "${dir_pkg}"
    tar -cvf - *
  ) > "${path_archive}"
  if [[ ${SKIP_XZ} == 'yes' ]]; then
    echo " -> Compressing skipped since SKIP_XZ=yes"
  else
    local path_archive_compressed="${dir_releases}/${name_archive_pkgs_compressed}"
    echo " -> Compressing archive to ${path_archive_compressed} ..."
    # Just single thread, we want best compression
    xz -9ecv "${path_archive}" > "${path_archive_compressed}"
  fi
  echo "=> Packages archive created"
}

make_archive_root() {
  echo "=> Creating rootfs archive..."
  local path_archive="${dir_releases}/${name_archive_root}"
  echo " -> Creating archive ${path_archive} without compression..."
  (
    cd "${dir_root}"
    sudo bsdtar --acls --xattrs -cvpf - *
  ) > "${path_archive}"
  if [[ "${SKIP_XZ}" == 'yes' ]]; then
    echo " -> Compressing skipped since SKIP_XZ=yes"
  else
    local path_archive_compressed="${dir_releases}/${name_archive_root_compressed}"
    echo " -> Compressing archive to ${path_archive_compressed} ..."
    # Just single thread, we want best compression
    xz -9ecv "${path_archive}" > "${path_archive_compressed}"
  fi
  echo "=> Rootfs archive created"
}

make_archive() {
  make_archive_pkgs
  make_archive_root
}

zero_fill() {
  echo "=> Filling zeroes to target root and boot fs for maximum compression"
  # if [[ "${SKIP_XZ}" == 'yes' ]]; then
  #   echo " -> Zero-fill skipped since SKIP_XZ=yes"
  # else
    echo " => Filling boot partition..."
    sudo dd if=/dev/zero of="${dir_boot}/.zerofill" || true
    echo " => Filling root partition..."
    sudo dd if=/dev/zero of="${dir_root}/.zerofill" || true
    sudo rm -f "${dir_boot}/.zerofill" "${dir_root}/.zerofill"
    echo "=> Zero fill successful"
  # fi
}

release_resource() {
  echo "=> Releasing resources..."
  echo " => Umouting partitions..."
  sudo umount -R "${dir_root}" 
  echo " => Removing temp folders..."
  sudo rm -rf "${dir_root}" 
  echo " => Detaching loopback device ${loop_disk}"
  sudo losetup -d "${loop_disk}"
  echo "=> Released resources"
}

compress_image() {
  echo "=> Compressing disk image..."
  if [[ "${SKIP_XZ}" == 'yes' ]]; then
    echo " -> Compressing skipped since SKIP_XZ=yes"
  else
    local path_disk="${dir_releases}/${name_disk}"
    local path_disk_compressed="${dir_releases}/${name_disk_compressed}"
    echo " => Compressing into ${path_disk_compressed}..."
    xz -9ecvT0 "${path_disk}" > "${path_disk_compressed}"
  fi
  echo "=> Compressing success"
}

release_note() {
  echo " => Generating release note..."
  local names=(
    'systemd'
    'openssh'
    'sudo'
    'vim'
    'ampart-git'
    'linux-aarch64-flippy'
    'linux-firmware-amlogic-ophub'
    'uboot-legacy-initrd-hooks'
    'yay'
  )
  local versions=()
  local name
  for name in "${names[@]}"; do
    versions+=($(grep $'^'"${name}"' .*' "${file_versions}" | cut -d ' ' -f 2))
  done
  printf "###%s\nBuild ID: %s\n|name|version|source|\n|-|-|-|\n|systemd|%s|official|\n|openssh|%s|official|\n|sudo|%s|official\n|vim|%s|official|\n|ampart-git|%s|[my AUR][AUR ampart-git]|\n|linux-aarch64-flippy|%s|[my AUR][AUR linux-aarch64-flippy-bin]|\n|linux-firmware-amlogic-ophub|%s|[my AUR][AUR linux-firmware-amlogic-ophub]\n|uboot-legacy-initrd-hooks|%s|[my AUR][AUR uboot-legacy-initrd-hooks]\n|yay|%s|[AUR][AUR yay]\n" "$(date +%Y%m%d)" "${name_date}" "${versions[0]}" "${versions[1]}" "${versions[2]}" "${versions[3]}" "${versions[4]}" "${versions[5]}" "${versions[6]}" "${versions[7]}" "${versions[8]}" > "${dir_releases}/${name_release_note}"
  rm -f "${file_versions}"
  echo " => Release note generated"
}

build() {
  echo "=> Build starts at $(date) <="
  sanity_check
  prepare
  deploy
  basic_setup
  run_inside
  get_versions
  cleanup
  make_archive
  zero_fill
  release_resource
  compress_image
  release_note
  echo "=> Build ends at $(date) <="
}

build