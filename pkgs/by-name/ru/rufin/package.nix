{
  lib,
  fetchFromGitHub,
  rustPlatform,
  cacert,
  cmake,
  glib,
  glib-networking,
  gettext,
  gst_all_1,
  gtk4,
  libadwaita,
  ninja,
  pkg-config,
  wrapGAppsHook4,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "rufin";
  version = "0.15.0";

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "screwys";
    repo = "Rufin";
    tag = "v${finalAttrs.version}";
    hash = "sha256-ps3lfdNAXJwlhgpwPMJFASq+DwGYy8ZTQAHffB+yfCM=";
  };

  cargoHash = "sha256-bDFO1wd96v/a/xEWgexDhwnWmbB5vAfsej6nMiDj9SI=";

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    gettext
    ninja
    pkg-config
    wrapGAppsHook4
  ];

  buildInputs = [
    glib
    glib-networking
    gtk4
    libadwaita
  ]
  ++ (with gst_all_1; [
    gstreamer
    gst-plugins-base
    gst-plugins-good
    gst-plugins-bad
    gst-plugins-ugly
    gst-libav
  ]);

  doCheck = false;

  env.SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";

  buildPhase = ''
    runHook preBuild

    cmake \
      -S . \
      -B build-cmake \
      -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX="$out" \
      -DRUFIN_BUILD_IDENTITY=stable \
      -DRUFIN_CARGO_FROZEN=ON
    cmake --build build-cmake --target rufin

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    cmake --install build-cmake
    substituteInPlace "$out/share/applications/io.github.screwys.Rufin.desktop" \
      --replace-fail "Exec=rufin" "Exec=$out/bin/rufin"

    runHook postInstall
  '';

  preFixup = ''
    gappsWrapperArgs+=(
      --set-default RUFIN_LOCALEDIR "$out/share/locale"
      --set-default SSL_CERT_FILE "${cacert}/etc/ssl/certs/ca-bundle.crt"
    )
  '';

  meta = {
    description = "Native GTK4/libadwaita music client for Jellyfin, Subsonic, Navidrome and local libraries written in Rust";
    homepage = "https://github.com/screwys/Rufin";
    changelog = "https://github.com/screwys/Rufin/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.gpl3Plus;
    maintainers = with lib.maintainers; [ screwys ];
    mainProgram = "rufin";
    platforms = lib.platforms.linux;
  };
})
