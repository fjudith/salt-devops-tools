# Setup Windows Subsystem for Linux 2 (WSL2)

Run the following command from a Windows Powershell or Powershell prompt with Administrator privileges.

```powershell
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all
```

Install WSL Preview and Ubuntu 22.04 LTS from the Microsoft Store

* [WSL Preview](https://aka.ms/wslstorepage)
* [Ubuntu 22.04](https://apps.microsoft.com/store/detail/ubuntu-22041-lts/9PN20MSR04DW)

## Configuring WSL with Git for Windows (recommended)

Start by installing the [latest Git for Windows](https://github.com/git-for-windows/git/releases/latest) ⬇️

Inside your WSL installation, run the following command to set GCM as the Git credential helper:

```shell
git config --global credential.helper "/mnt/c/Program\ Files/Git/mingw64/bin/git-credential-manager.exe"
```

> **Note**: the location of git-credential-manager.exe may be different in your installation of Git for Windows.

If you intend to use Azure DevOps you must also set the following Git configuration inside of your WSL installation.

```shell
git config --global credential.https://dev.azure.com.useHttpPath true
```

## Enable Systemd

Launch the Ubuntu distribution, then run the following command to enable SystemD.

```shell
cat <<EOF | sudo tee -a /etc/wsl.conf
[boot]
systemd = true
EOF
```

From a CMD prompt, run the following command to stop the WSL engine.

```shell
wsl --shutdown
```

Relauch the Ubuntu distribution.
