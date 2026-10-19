# Eventide's Banpilot

[![Buy Me a Coffee](https://img.shields.io/badge/Buy_Me_a_Coffee-Support_Manafield-FFDD00?style=for-the-badge&logo=buymeacoffee&logoColor=000000)](https://buymeacoffee.com/manafield)

> 어째서.
>
> 어째서 오른쪽 아래에, 가장 중요한 지점에 코파일럿 키를 박아두었는가.
>
> 용서할 수 없다.

**내 키보드에 네 자리는 없다.**

Copilot 키를 눌렀을 때 **아무 동작 안 함** 또는 **Windows 키 한 번 누르기**를 선택하는 작은 Windows 앱입니다.
Windows의 Copilot 키 사용자 지정에서 원하는 Banpilot 항목을 실행 대상으로 선택합니다.

현재 버전은 **0.2.0**입니다. 기존 무동작 모드를 유지하면서 Windows 키를 한 번 누르는 모드를 추가했습니다.

같은 패키지에 두 앱을 등록하는 방식입니다. 시스템의 최상위 선택지를 추가하는 것이 아니라 **앱 열기 → 앱 선택** 목록에 두 항목이 표시됩니다. 로컬 Windows 11 25H2 PC에서 두 항목 표시를 확인했습니다.

| 선택 항목 | 동작 |
| --- | --- |
| Eventide's Banpilot - 아무 동작 안 함 | 창 없이 즉시 종료합니다. |
| Eventide's Banpilot - Windows 키 한 번 누르기 | 원래 입력이 해제된 뒤 RWindows DOWN/UP을 한 번 보내고 종료합니다. 시작 메뉴 열기가 의도한 동작입니다. |

RCtrl처럼 누르는 상태를 유지하거나 `Win+E` 조합을 만드는 기능은 아닙니다. [기존 RCtrl 연구 기록](docs/rctrl-research.md)은 별도로 남겨둡니다.

## 동작

- 무동작 모드의 실행 코드는 기존과 같은 `return 0;`입니다.
- Windows 키 모드는 Win/Shift/Ctrl/Alt/F23 및 `Win+C`의 C 키가 모두 해제된 상태를 100ms 확인한 뒤 한 번 입력합니다. 키 상태만 확인하며 입력 내용을 기록하지 않습니다.
- 대기는 최대 15초이며, 시간이 지나거나 입력 데스크톱에 접근할 수 없으면 입력을 보내지 않고 종료합니다. 잠금 상태에서는 실행하지 않는 방향으로 구현했으며 실제 잠금 전환 검증은 별도입니다.
- 시작 프로그램, 서비스, 상시 실행 프로세스, 키 입력 후킹, 네트워크 통신이 없습니다. Windows 키 모드는 호출 후 해제를 기다리는 동안만 실행됩니다.
- 겹쳐 실행된 Windows 키 프로세스는 중복 입력을 보내지 않고 종료합니다.
- 키보드 드라이버, Secure Boot, 테스트 모드 설정을 변경하지 않습니다.
- 원래 물리 키 입력을 차단하지 않습니다. Windows가 호출할 앱을 바꾸고, Windows 키 모드에서만 별도의 입력을 합성합니다.
- Windows 설정에 따라 `Win+C`에도 같은 앱이 연결될 수 있습니다.

Windows 11 x64용 실험 프로젝트입니다. 짧게 누르기, 길게 누르기, 다른 키와 함께 누르기의 동작은 실제 PC에서 확인해야 합니다.

관리자 권한 앱, 보호된 화면, 게임 등에서는 입력 합성이 제한될 수 있습니다. 키 상태 확인과 입력 전송 사이의 매우 짧은 경합, 프로세스 강제 종료까지 완전히 해결했다고 보장하지 않습니다. 앱을 직접 실행해도 해당 모드의 동작을 수행합니다.

## 설치 및 선택

1. [최신 릴리스](https://github.com/eventide-manafield/Banpilot/releases/latest)에서 **`Banpilot-버전-Setup-x64.exe`를 내려받아 더블클릭**합니다. 압축 해제나 별도 빌드 도구가 필요하지 않습니다.
2. 처음 설치할 때 설치기가 로컬 테스트용 공개 인증서 `CN=Eventide Banpilot Test`를 `LocalMachine\TrustedPeople`에 등록합니다. 관리자 권한이 필요합니다. 완료 메시지를 확인하고 창을 닫습니다.
3. Windows 설정의 **키보드의 Copilot 키 사용자 지정**에서 사용자 지정 앱을 선택합니다. Windows 버전에 따라 개인 설정 → 텍스트 입력 또는 Bluetooth 및 장치 → 키보드에 있습니다.
4. **Eventide's Banpilot - 아무 동작 안 함** 또는 **Eventide's Banpilot - Windows 키 한 번 누르기**를 선택합니다.
5. 무동작 모드는 창이 뜨지 않는지, Windows 키 모드는 손을 뗀 뒤 시작 메뉴가 한 번 열리는지 확인합니다.

기존 무동작 모드의 앱 ID `App`은 유지하고 Windows 키 모드는 별도 ID `WindowsKey`로 등록합니다. 업데이트 후 기존 연결이 유지됐는지도 확인하십시오.

설치기는 앱과 인증서를 설치합니다. Copilot 키의 실행 대상은 Windows 설정에서 선택합니다. 앱 목록에 나타나지 않으면 설정 창을 다시 엽니다.

설치와 앱 선택은 한 번만 하면 됩니다. 이후 Copilot 키를 누르면 Windows가 선택한 앱을 실행합니다. Setup EXE에는 MSIX·공개 인증서·설치 스크립트가 내장되어 있으며, 실행 시 임시 폴더에서 설치한 뒤 임시 파일을 정리합니다. 설치 파일을 별도로 다운로드하지 않습니다.

배치 파일을 선호한다면 `Banpilot-버전-windows-x64.zip`을 **모두 압축 해제**한 뒤 `Install.bat`을 실행할 수도 있습니다. 이 경우 설치 파일들을 같은 폴더에 유지해야 합니다. GitHub가 자동 제공하는 소스 코드 ZIP과는 다른 파일입니다.

릴리스의 `SHA256SUMS.txt`와 `Get-FileHash .\Banpilot-0.2.0-Setup-x64.exe -Algorithm SHA256` 결과를 비교하여 다운로드한 파일을 확인할 수 있습니다.

### 테스트 인증서

이 패키지는 자체 서명된 로컬 테스트 빌드입니다. 인증서 신뢰 등록은 앱을 종료한 후에도 남으며, 같은 인증서로 서명한 다른 코드의 신뢰 판단에도 영향을 줄 수 있습니다. 앱의 안전성을 외부 기관이 보증하는 것은 아닙니다.

배포 파일에는 공개 인증서 `.cer`만 포함합니다. 개인 키는 Windows의 현재 사용자 인증서 저장소에 비내보내기 키로 보관하며, Git 저장소나 배포 파일에 포함하지 않습니다. 소스와 빌드 스크립트를 먼저 확인하십시오.

## 빌드 및 확인

Windows PowerShell 5.1, Windows에 포함된 .NET Framework 컴파일러, Windows SDK `10.0.26100.0`의 x64 도구를 사용합니다.

```powershell
powershell.exe -NoProfile -File .\Build.ps1
```

`out` 아래 새 폴더에 MSIX, 공개 인증서, 설치기, 해시 및 인증서 지문이 담긴 `build.json`이 생성됩니다. 다른 PC에서 소스를 빌드하면 그 PC의 로컬 테스트 인증서를 생성합니다.

단일 Setup EXE, 설치용 ZIP 및 SHA-256 파일 생성:

```powershell
powershell.exe -NoProfile -File .\Package.ps1
```

버전과 MSIX 파일명은 매니페스트에서 결정합니다. Setup EXE도 앱과 같은 인증서로 서명합니다. 배포물에는 설치에 필요한 파일과 공개 인증서만 포함하며, 개인 키·중간 빌드 파일·로컬 진단 기록은 포함하지 않습니다. Setup EXE의 `--check-only` 옵션은 설치 없이 내장 파일의 해시와 서명을 검사합니다.

설치 전 패키지 확인:

```powershell
powershell.exe -NoProfile -File .\Install.ps1 -ReleaseDirectory (Get-Content .\out\latest.txt) -CheckOnly
```

설치 후 공급자 등록 및 앱 활성화 확인:

```powershell
powershell.exe -NoProfile -File .\Verify-Installed.ps1
```

자동 확인은 두 공급자 등록, 무동작 앱의 활성화·종료, Windows 키 앱의 `--dry-run` 활성화·종료를 검사합니다. `--dry-run`은 실제 입력을 보내지 않습니다. 잠금을 해제하고 키에서 손을 뗀 상태에서 실행하십시오. 실제 Copilot 키, 시작 메뉴 열림, 길게 누르기, 재로그인·재부팅 후 동작을 대신 검증하지 않습니다.

키 입력을 보내지 않는 로직 테스트:

```powershell
powershell.exe -NoProfile -File .\Test.ps1
```

실제 Windows API 대신 가짜 입력 환경을 사용합니다. 해제 대기, 재누름, 제한 시간, 데스크톱 접근 실패, 마지막 순간의 수정 키 입력, 합성 실패·일부 성공 시 정리, x64 입력 구조를 검사합니다.

### 0.2.0 개발 검증 상태

- 입력을 보내지 않는 로직 테스트 11개 및 두 공급자 항목의 매니페스트 검사 통과
- MSIX 빌드·기존 테스트 인증서로 서명·설치 전 해시/서명 검사 통과
- 0.1.0에서 0.2.0으로 설치 업데이트, 두 공급자 등록 및 Windows 설정의 두 항목 표시 확인
- 기존 무동작 연결 유지, 이후 Windows 키 모드 선택과 저장된 연결 값 확인
- 무동작 활성화·종료 및 Windows 키 모드의 입력 없는 dry run 통과
- 2026-10-19 업데이트 후 사용자에게 기본 동작 확인 및 버전 반영 승인을 받음
- 길게 누르기, 다른 키와의 조합, 잠금 전환 및 재로그인·재부팅 후 동작의 체계적인 검증은 아직 완료하지 않음

### 기존 0.1.0 검증 기록

2026-10-19 로컬 Windows 11 25H2 x64 PC에서 다음을 확인했습니다.

- MSIX 빌드·서명, 테스트 인증서 신뢰 등록, 앱 설치 성공
- Copilot 키 공급자 등록과 Windows 설정 앱 선택 목록 표시 확인
- 패키지 활성화 5회 모두 종료 및 전경 창 유지 확인, 상주 프로세스 없음
- Windows 설정에서 Banpilot 선택 후 저장된 Copilot 키 연결 값 확인
- 사용자 실사용에서 무동작으로 보인다는 초기 피드백을 받음. 음소거 상태였으므로 음성 동작까지 검증된 것으로 간주하지 않음
- 실제 키의 짧게·길게 누르기, 다른 키와의 조합, 재로그인·재부팅 후 검증은 아직 완료하지 않음

## 제거 및 복구

1. Windows 설정에서 Copilot 키의 실행 대상을 원하는 앱으로 다시 선택합니다.
2. 설치된 앱에서 **Eventide's Banpilot**을 제거합니다.
3. 이 테스트 인증서를 더 이상 사용하지 않으면 `certlm.msc`의 **신뢰할 수 있는 사람 → 인증서**에서 `build.json`의 지문과 정확히 일치하는 인증서를 제거합니다. 다른 앱에서도 같은 인증서를 사용하는지 먼저 확인하십시오.

## 참고

- [Microsoft Copilot hardware key providers](https://learn.microsoft.com/en-us/windows/apps/develop/windows-integration/microsoft-copilot-key-provider)
- [MSIX 자체 서명 인증서](https://learn.microsoft.com/en-us/windows/msix/package/create-certificate-package-signing)
