{
  lib,
  stdenvNoCC,
  makeWrapper,
  bash,
  coreutils,
  findutils,
  gawk,
  gnused,
  git,
}:

let
  version = (lib.importJSON ../.claude-plugin/plugin.json).version;
  runtimePath = lib.makeBinPath [
    coreutils
    findutils
    gawk
    gnused
  ];
in
stdenvNoCC.mkDerivation {
  pname = "claude-message-queue";
  inherit version;

  src = lib.fileset.toSource {
    root = ../.;
    fileset = lib.fileset.unions [
      ../.claude-plugin
      ../bin
      ../hooks
      ../skills
      ../tests
      ../LICENSE
      ../README.md
    ];
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ bash ];
  nativeCheckInputs = [ git ];

  dontConfigure = true;
  dontBuild = true;

  postPatch = ''
    patchShebangs bin hooks tests
  '';

  doCheck = true;
  checkPhase = ''
    runHook preCheck
    export HOME="$TMPDIR"
    tests/test-claude-queue.sh
    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall

    share="$out/share/claude-message-queue"
    mkdir -p "$out/bin" "$share/bin"

    # Plugin tree, usable with `claude --plugin-dir $out/share/claude-message-queue`.
    cp -r .claude-plugin hooks skills LICENSE README.md "$share/"

    install -Dm0755 bin/claude-queue "$share/bin/.claude-queue-unwrapped"
    # coreutils/findutils/awk/sed are required; git is optional (used for project identity),
    # so it is appended to PATH and the caller's git wins when present.
    makeWrapper "$share/bin/.claude-queue-unwrapped" "$share/bin/claude-queue" \
      --prefix PATH : ${runtimePath} \
      --suffix PATH : ${lib.makeBinPath [ git ]}
    ln -s "$share/bin/claude-queue" "$out/bin/claude-queue"

    # Claude Code runs the Stop hook with its own PATH; give it the same tools.
    wrapProgram "$share/hooks/stop-drain.sh" --prefix PATH : ${runtimePath}

    runHook postInstall
  '';

  meta = {
    description = "Durable, non-interrupting next-turn message queue for Claude Code";
    homepage = "https://github.com/imdewan/claude-message-queue";
    license = lib.licenses.mit;
    mainProgram = "claude-queue";
    platforms = lib.platforms.unix;
  };
}
