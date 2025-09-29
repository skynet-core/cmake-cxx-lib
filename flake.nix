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
        ];
        buildInputs = with pkgs; [
            cli11
            boost188
            openssl
            catch2_3
        ];
        shellHook = ''
                cat << EOF | cc -x c++ -
                #include <iostream>
                #include <filesystem>
                int main() {
                    std::cout << std::filesystem::path{"/"} << " Hello, World"<< std::endl;
                    return 0;
                }
                EOF
                rm a.out
              '';
        gccShell = pkgs.mkShell.override {
          stdenv = gccStdenv;
        }{
          packages = commonNativePackages;
          inherit buildInputs;
          inherit shellHook;
        };
        llvmShell = pkgs.mkShell.override {
          stdenv = llvmStdenv;
        }{
          packages = commonNativePackages;
          inherit buildInputs;
          inherit shellHook;
        };
      in
      {
        packages.default = gccStdenv.mkDerivation {
          pname = "cup-http";
          version = "0.1.0";
          inherit src;
          inherit buildInputs;
          nativeBuildInputs = commonNativePackages ++ [];
          cmakeFlags = [
            "-DCMAKE_CXX_STANDARD=23"
            "-DCMAKE_CXX_EXTENSIONS=OFF"
            "-DCMAKE_CXX_STANDARD_REQUIRED=ON"
            "-DCUP_STANDALONE_PACKAGE=OFF"
          ];
          __structuredAttrs = true;
        };
        devShells =  {
          default = llvmShell;
          gcc = gccShell;
          llvm = llvmShell;
        };
      }
    );
}
