{ 
  pkgs, 
  lib, 
  fetchFromGitHub, 
  stdenv,
  cmake,
}:

stdenv.mkDerivation {
  pname = "modbus";
  version = "2024.4.1";

  src = fetchFromGitHub {
    owner = "centroid-is";
    repo  = "modbus";
    rev = "26264ee8cc98798f2f93898562d0d5c9157d6bb9";
    sha256 = "J+XYaQXtJyM6QUjZlXDoiZy8UqBY5+zBLNx4sX6B7AI=";
  };

  nativeBuildInputs = with pkgs; [
    cmake
  ];

  buildInputs = with pkgs; [
    ut
    asio
    pkg-config
  ];

  meta = with lib; {
    description = "Modbus protocol implementation, based on boost asio";
    homepage = "https://github.com/centroid-is/modbus";
    license = licenses.bsd3;
  };
}
