{
  description = "HTTP Client Library | CUP - C (++) Ultimate Package manager";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.2505.810395";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        lib = pkgs.lib;
        fs = lib.fileset;
        llvm = pkgs.llvmPackages_20;
        gccStdenv = pkgs.gcc15Stdenv;
        llvmStdenv = llvm.stdenv;
        src = fs.toSource {
          root = ./.;
          fileset = fs.unions [
            (fs.gitTracked ./.)
            (fs.fromSource ./cmake)
            (fs.fromSource ./cpack)
          ];
        };
        commonNativePackages = with pkgs; [
          fish
          cmake
          ninja
          llvm.clang-tools
          patchelf
          dpkg
          rpm
          llvm.lld
          nixd
          nixfmt-rfc-style
        ];
        buildInputs = with pkgs; [
          cli11
          boost
          openssl
          catch2_3
        ];
        shellHook = ''
          echo "Checking compiler ..."
          cat <<EOF | c++ -x c++ -
            #include <iostream>
            #include <filesystem>
            int main() {
              std::cout << std::filesystem::current_path() << "\n" << "Compiler works!"<< std::endl;
              return 0;
            }
          EOF
          ./a.out 1>/dev/null 2>&1
          rm ./a.out || true
        '';
        gccShell =
          pkgs.mkShell.override
            {
              stdenv = gccStdenv;
            }
            {
              packages = commonNativePackages;
              buildInputs = buildInputs ++ [ gccStdenv ];
              inherit shellHook;
            };
        llvmShell =
          pkgs.mkShell.override
            {
              stdenv = llvmStdenv;
            }
            {
              packages = commonNativePackages;
              buildInputs = buildInputs ++ [ llvmStdenv ];
              inherit shellHook;
            };
      in
      {
        packages.default = gccStdenv.mkDerivation {
          pname = "cup-http";
          version = "0.1.0";
          inherit src;
          inherit buildInputs;
          nativeBuildInputs = commonNativePackages ++ [ ];
          cmakeFlags = [
            "-DCMAKE_CXX_STANDARD=23"
            "-DCMAKE_CXX_EXTENSIONS=OFF"
            "-DCMAKE_CXX_STANDARD_REQUIRED=ON"
            "-DCUP_STANDALONE_PACKAGE=OFF"
          ];
          __structuredAttrs = true;
        };
        devShells = {
          default = llvmShell;
          gcc = gccShell;
          llvm = llvmShell;
        };
      }
    );
}
