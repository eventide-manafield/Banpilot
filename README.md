# Eventide's Banpilot

[다운로드 · Releases](https://github.com/eventide-manafield/Banpilot/releases/latest)

[![Buy Me a Coffee](https://img.shields.io/badge/Buy_Me_a_Coffee-Support_Manafield-FFDD00?style=for-the-badge&logo=buymeacoffee&logoColor=000000)](https://buymeacoffee.com/manafield)

[한국어](#한국어) · [English](#english)

I'm a Korean developer. I wrote this README in Korean, and ChatGPT translated it into English.

---

## 한국어

> 어째서.
>
> 어째서 오른쪽 아래에, 가장 중요한 지점에 코파일럿 키를 박아두었는가.
>
> 용서할 수 없다.

**내 키보드에 네 자리는 없다.**

Copilot 키를 눌렀을 때 **아무 동작 안 함** 또는 **Windows 키 한 번 누르기**를 선택하는 작은 Windows 앱입니다.
Windows의 Copilot 키 사용자 지정에서 원하는 Banpilot 항목을 실행 대상으로 선택합니다.

현재 소스의 버전은 **0.2.2**입니다. 한국어·영어 표시와 설치기 안내를 추가했습니다. 공개된 설치 파일의 버전은 상단 릴리스 링크에서 확인하세요.

같은 패키지에 두 앱을 등록하는 방식입니다. 시스템의 최상위 선택지를 추가하는 것이 아니라 **앱 열기 → 앱 선택** 목록에 두 항목이 표시됩니다. 로컬 Windows 11 25H2 PC에서 두 항목 표시를 확인했습니다.

이 프로그램은 ChatGPT, Codex를 사용하여 만들어졌습니다.

| 선택 항목 | 동작 |
| --- | --- |
| Eventide's Banpilot - 아무 동작 안 함 | 창 없이 즉시 종료합니다. |
| Eventide's Banpilot - Windows 키 한 번 누르기 | 원래 입력이 해제된 뒤 RWindows DOWN/UP을 한 번 보내고 종료합니다. 시작 메뉴 열기가 의도한 동작입니다. |

RCtrl처럼 누르는 상태를 유지하거나 `Win+E` 조합을 만드는 기능은 아닙니다. [기존 RCtrl 연구 기록](docs/rctrl-research.md)은 별도로 남겨둡니다.

### 동작

#### 표시 언어

0.2.2부터 Windows 앱 선택 목록의 이름과 설명을 한국어·영어로 제공합니다. Windows의 선호 언어 설정에 맞춰 표시하며, 일치하는 지원 언어가 없으면 영어를 사용합니다. 여러 선호 언어 중 한국어가 포함된 경우 Windows가 한국어를 선택할 수 있습니다.

Setup EXE와 배치 설치기의 자체 안내·오류 메시지는 현재 사용자의 Windows 표시 언어가 한국어(`ko`)이면 한국어, 그 외에는 영어입니다. 지역별 날짜·숫자 형식이나 키보드 입력 언어와는 별개입니다. Windows가 직접 출력하는 UAC·배포 오류와 개발용 진단 메시지는 운영체제 또는 도구의 언어를 따릅니다.

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

### 설치 및 선택

1. [최신 릴리스](https://github.com/eventide-manafield/Banpilot/releases/latest)에서 **`Banpilot-버전-Setup-x64.exe`를 내려받아 더블클릭**합니다. 압축 해제나 별도 빌드 도구가 필요하지 않습니다.
2. 처음 설치할 때 설치기가 로컬 테스트용 공개 인증서 `CN=Eventide Banpilot Test`를 `LocalMachine\TrustedPeople`에 등록합니다. 관리자 권한이 필요합니다. 완료 메시지를 확인하고 창을 닫습니다.
3. Windows 설정의 **키보드의 Copilot 키 사용자 지정**에서 사용자 지정 앱을 선택합니다. Windows 버전에 따라 개인 설정 → 텍스트 입력 또는 Bluetooth 및 장치 → 키보드에 있습니다.
4. **Eventide's Banpilot - 아무 동작 안 함** 또는 **Eventide's Banpilot - Windows 키 한 번 누르기**를 선택합니다.
5. 무동작 모드는 창이 뜨지 않는지, Windows 키 모드는 손을 뗀 뒤 시작 메뉴가 한 번 열리는지 확인합니다.

기존 무동작 모드의 앱 ID `App`은 유지하고 Windows 키 모드는 별도 ID `WindowsKey`로 등록합니다. 업데이트 후 기존 연결이 유지됐는지도 확인하십시오.

설치기는 앱과 인증서를 설치합니다. Copilot 키의 실행 대상은 Windows 설정에서 선택합니다. 앱 목록에 나타나지 않으면 설정 창을 다시 엽니다.

설치와 앱 선택은 한 번만 하면 됩니다. 이후 Copilot 키를 누르면 Windows가 선택한 앱을 실행합니다. Setup EXE에는 MSIX·공개 인증서·설치 스크립트·두 언어의 안내 문구가 내장되어 있으며, 실행 시 임시 폴더에서 설치한 뒤 임시 파일을 정리합니다. 설치 파일을 별도로 다운로드하지 않습니다.

배치 파일을 선호한다면 `Banpilot-버전-windows-x64.zip`을 **모두 압축 해제**한 뒤 `Install.bat`을 실행할 수도 있습니다. 이 경우 설치 파일들을 같은 폴더에 유지해야 합니다. GitHub가 자동 제공하는 소스 코드 ZIP과는 다른 파일입니다.

릴리스의 `SHA256SUMS.txt`와 `Get-FileHash .\Banpilot-0.2.2-Setup-x64.exe -Algorithm SHA256` 결과를 비교하여 다운로드한 파일을 확인할 수 있습니다.

#### 테스트 인증서

이 패키지는 자체 서명된 로컬 테스트 빌드입니다. 인증서 신뢰 등록은 앱을 종료한 후에도 남으며, 같은 인증서로 서명한 다른 코드의 신뢰 판단에도 영향을 줄 수 있습니다. 앱의 안전성을 외부 기관이 보증하는 것은 아닙니다.

배포 파일에는 공개 인증서 `.cer`만 포함합니다. 개인 키는 Windows의 현재 사용자 인증서 저장소에 비내보내기 키로 보관하며, Git 저장소나 배포 파일에 포함하지 않습니다. 소스와 빌드 스크립트를 먼저 확인하십시오.

### 빌드 및 확인

Windows PowerShell 5.1, Windows에 포함된 .NET Framework 컴파일러, Windows SDK `10.0.26100.0`의 x64 도구를 사용합니다. 언어 리소스 생성에는 SDK의 MakePRI를 사용합니다.

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

실제 Windows API 대신 가짜 입력 환경을 사용합니다. 해제 대기, 재누름, 제한 시간, 데스크톱 접근 실패, 마지막 순간의 수정 키 입력, 합성 실패·일부 성공 시 정리, x64 입력 구조를 검사합니다. 언어 테스트는 한국어 선택, 다른 언어의 영어 대체, 지역 형식과 표시 언어의 독립성, 번역 키 일치 및 매니페스트의 리소스 참조를 검사합니다.

#### 0.2.0 개발 검증 상태

- 입력을 보내지 않는 로직 테스트 11개 및 두 공급자 항목의 매니페스트 검사 통과
- MSIX 빌드·기존 테스트 인증서로 서명·설치 전 해시/서명 검사 통과
- 0.1.0에서 0.2.0으로 설치 업데이트, 두 공급자 등록 및 Windows 설정의 두 항목 표시 확인
- 기존 무동작 연결 유지, 이후 Windows 키 모드 선택과 저장된 연결 값 확인
- 무동작 활성화·종료 및 Windows 키 모드의 입력 없는 dry run 통과
- 2026-10-19 업데이트 후 사용자에게 기본 동작 확인 및 버전 반영 승인을 받음
- 길게 누르기, 다른 키와의 조합, 잠금 전환 및 재로그인·재부팅 후 동작의 체계적인 검증은 아직 완료하지 않음

#### 기존 0.1.0 검증 기록

2026-10-19 로컬 Windows 11 25H2 x64 PC에서 다음을 확인했습니다.

- MSIX 빌드·서명, 테스트 인증서 신뢰 등록, 앱 설치 성공
- Copilot 키 공급자 등록과 Windows 설정 앱 선택 목록 표시 확인
- 패키지 활성화 5회 모두 종료 및 전경 창 유지 확인, 상주 프로세스 없음
- Windows 설정에서 Banpilot 선택 후 저장된 Copilot 키 연결 값 확인
- 사용자 실사용에서 무동작으로 보인다는 초기 피드백을 받음. 음소거 상태였으므로 음성 동작까지 검증된 것으로 간주하지 않음
- 실제 키의 짧게·길게 누르기, 다른 키와의 조합, 재로그인·재부팅 후 검증은 아직 완료하지 않음

### 제거 및 복구

1. Windows 설정에서 Copilot 키의 실행 대상을 원하는 앱으로 다시 선택합니다.
2. 설치된 앱에서 **Eventide's Banpilot**을 제거합니다.
3. 이 테스트 인증서를 더 이상 사용하지 않으면 `certlm.msc`의 **신뢰할 수 있는 사람 → 인증서**에서 `build.json`의 지문과 정확히 일치하는 인증서를 제거합니다. 다른 앱에서도 같은 인증서를 사용하는지 먼저 확인하십시오.

### 라이선스

[MIT + Commons Clause 1.0](LICENSE) — Copyright (c) 2026 Eventide (eventide-manafield).

0.2.1부터 설치 ZIP의 루트와 MSIX 앱 패키지에 LICENSE 파일을 포함합니다. 단일 Setup EXE에도 이 MSIX가 내장되므로, 설치 후 앱 설치 폴더에서 라이선스 전문을 확인할 수 있습니다.

개인 사용, 회사 업무에서의 사용, 수정 및 조건을 준수한 재배포를 허용합니다. 프로그램 기능에서 가치가 전부 또는 상당 부분 나오는 상품·서비스의 유료 제공은 Commons Clause의 **Sell** 정의에 따라 제한됩니다. 이름이나 아이콘만 바꾼 유료 판매, 해당 정의에 해당하는 유료 호스팅·지원 서비스도 제한 대상입니다.

프로그램을 더 큰 제품에 포함하는 것 자체는 금지하지 않습니다. 예를 들어 가치의 중심이 하드웨어인 일반적인 PC 판매에 편의 프로그램으로 설치해 주는 것은 허용 취지에 부합합니다. 다만 모든 묶음 판매나 유료 지원이 무조건 허용되는 것은 아니며, 구체적인 판단은 Sell 정의를 따릅니다. 재배포 시 저작권 고지와 **MIT 및 Commons Clause 전체 문구**를 함께 보존해야 합니다.

공식 원문인 [MIT](https://opensource.org/license/mit)와 [Commons Clause 1.0](https://commonsclause.com/)을 함께 사용합니다. 별도의 자체 제한 조항을 추가하지 않았습니다. MIT만 단독으로 적용하는 것이 아니며, 판매 제한이 있으므로 **OSI 승인 오픈소스가 아닌 소스 공개(source-available) 소프트웨어**입니다. 이 문단은 안내용 요약이며 정확한 조건은 영문 LICENSE 파일을 따릅니다.

**이전 공개분:** v0.2.0 및 과거 MIT로 공개된 코드에 이미 부여한 권한은 유지됩니다. 이 변경은 그 권한을 소급해서 취소하지 않으며, 과거 MIT 공개분의 판매까지 제한하지 않습니다.

### 참고

- [Microsoft Copilot hardware key providers](https://learn.microsoft.com/en-us/windows/apps/develop/windows-integration/microsoft-copilot-key-provider)
- [MSIX 자체 서명 인증서](https://learn.microsoft.com/en-us/windows/msix/package/create-certificate-package-signing)

[맨 위로](#eventides-banpilot) · [English](#english)

---

## English

> Why.
>
> Why put a Copilot key in that precious spot at the bottom right of the keyboard?
>
> Unforgivable.

**There is no place for you on my keyboard.**

Banpilot is a small Windows app that lets you choose **Do nothing** or **Press Windows key once** when you press the Copilot key. Select the desired Banpilot entry in Windows' Copilot key customization setting.

The current source version is **0.2.2**, adding Korean and English labels and installer messages. Check the release link at the top for the version of the published installers.

The package registers two apps. They appear under **Open an app → Select an app**, rather than adding new top-level Windows settings options. Both entries were verified on a local Windows 11 25H2 PC.

This program was created using ChatGPT and Codex.

| App entry | Behavior |
| --- | --- |
| Eventide's Banpilot - Do nothing | Opens no window and exits immediately. |
| Eventide's Banpilot - Press Windows key once | Waits for the original keys to be released, sends one RWindows DOWN/UP pair, then exits. Opening Start is the intended behavior. |

This does not hold a modifier such as RCtrl or enable combinations such as `Win+E`. The earlier [RCtrl research notes](docs/rctrl-research.md) are available separately in Korean.

### Behavior

#### Display language

Starting with 0.2.2, app names and descriptions in Windows' app picker are available in Korean and English. Windows selects them using its preferred-language settings, with English as the fallback when no supported language matches. If Korean is included among multiple preferred languages, Windows may select Korean.

The Setup EXE and batch installer's own instructions and error messages use Korean when the current user's Windows UI language is Korean (`ko`), and English otherwise. This is independent of regional date/number formats and keyboard input languages. UAC, Windows deployment errors, and developer diagnostics follow the operating system's or tool's language.

- The no-action app still runs the equivalent of `return 0;`.
- The Windows-key app waits until Win/Shift/Ctrl/Alt/F23 and the C key used by `Win+C` have all been released for 100 ms, then sends one key press. It checks key states without recording what you type.
- It waits for at most 15 seconds and exits without sending input if the timeout expires or the input desktop is inaccessible. Lock-transition behavior still needs separate real-world testing.
- There are no startup entries, services, permanently running processes, keyboard hooks, or network connections. The Windows-key app runs only while handling an activation and waiting for release.
- Overlapping Windows-key processes exit without sending duplicate input.
- It does not change keyboard drivers, Secure Boot, or test-signing settings.
- It does not block the original physical key input. It changes which app Windows launches; only the Windows-key mode synthesizes another input.
- Windows settings may also associate the selected app with `Win+C`.

This is an experimental Windows 11 x64 project. Test short presses, long presses, and combinations with other keys on your own PC.

Input synthesis may be restricted in elevated apps, protected screens, and games. It does not guarantee protection against the short race between checking key state and sending input, or against forced process termination. Launching either app directly also performs that app's behavior.

### Install and select

1. Download **`Banpilot-VERSION-Setup-x64.exe`** from the [latest release](https://github.com/eventide-manafield/Banpilot/releases/latest) and double-click it. No manual extraction or build tools are needed.
2. On first installation, the installer registers the local test certificate `CN=Eventide Banpilot Test` in `LocalMachine\TrustedPeople`. This requires administrator permission. Read the completion message before closing the window.
3. Search Windows Settings for **Copilot key** and choose a custom app. Depending on the Windows version, the setting is under Personalization → Text input or Bluetooth & devices → Keyboard.
4. Select **Eventide's Banpilot - Do nothing** or **Eventide's Banpilot - Press Windows key once**. These names appear in Korean when Windows selects Korean resources.
5. Check that no window opens in no-action mode, or that Start opens once after you release the key in Windows-key mode.

The original no-action app keeps its ID, `App`. The Windows-key app has a separate ID, `WindowsKey`. Check that your existing assignment is preserved after updating.

The installer installs the app and certificate. Choose the Copilot key's target yourself in Windows Settings. Reopen Settings if the entries do not appear.

Installation and selection are only needed once. Windows then launches the selected app when you press the Copilot key. The Setup EXE embeds the MSIX, public certificate, installation script, and both installer language resources. It extracts them to a temporary folder for installation and cleans up afterward; it does not download additional installation files.

For a batch installer, download **`Banpilot-VERSION-windows-x64.zip`**, extract everything, and run `Install.bat`. Keep its files together. This is different from GitHub's automatically generated source-code ZIP.

Compare the release's `SHA256SUMS.txt` with the output of `Get-FileHash .\Banpilot-0.2.2-Setup-x64.exe -Algorithm SHA256` to verify your download; substitute your downloaded version's filename.

#### Test certificate

This package is a self-signed local test build. Certificate trust remains after the app exits and may affect trust decisions for other code signed with the same certificate. An external authority has not certified the app's safety.

Only the public `.cer` certificate is distributed. The private key is kept as a non-exportable key in the builder's current-user Windows certificate store and is not included in Git or release files. Review the source and build scripts first.

### Build and verify

The build uses Windows PowerShell 5.1, Windows' bundled .NET Framework compiler, and x64 tools from Windows SDK `10.0.26100.0`, including MakePRI for language resources.

```powershell
powershell.exe -NoProfile -File .\Build.ps1
```

A new folder under `out` contains the MSIX, public certificate, installer files, and `build.json` with the package hash and certificate thumbprint. Building on another PC creates that PC's local test certificate.

Create the standalone Setup EXE, installation ZIP, and SHA-256 checksum file:

```powershell
powershell.exe -NoProfile -File .\Package.ps1
```

The manifest determines the version and MSIX filename. The Setup EXE is signed with the same certificate as the app. Release files contain installation files and the public certificate, but no private keys, intermediate build files, or local diagnostic records. The Setup EXE's `--check-only` option verifies the embedded package hash and signature without installing it.

Verify before installation:

```powershell
powershell.exe -NoProfile -File .\Install.ps1 -ReleaseDirectory (Get-Content .\out\latest.txt) -CheckOnly
```

Verify provider registration and app activation after installation:

```powershell
powershell.exe -NoProfile -File .\Verify-Installed.ps1
```

This checks both registered providers, no-action activation and exit, and Windows-key activation and exit using `--dry-run`, which sends no input. Run it while unlocked with all keys released. It does not replace physical-key tests, Start-menu checks, long holds, or testing after sign-in and reboot.

Run the logic and localization tests without sending keyboard input:

```powershell
powershell.exe -NoProfile -File .\Test.ps1
```

The input tests use a fake host instead of Windows input APIs. They cover release waits, re-presses, timeouts, inaccessible desktops, last-moment modifiers, failed or partial input injection, and the x64 input layout. Localization tests check Korean selection, English fallback for other languages, independence from regional formatting, matching translation keys, and manifest resource references.

#### 0.2.0 validation history

- Passed 11 input-logic tests and manifest checks for both provider entries.
- Built and signed the MSIX with the existing test certificate; passed hash/signature checks.
- Updated the local installation from 0.1.0 to 0.2.0 and verified both provider registrations and app-picker entries.
- Verified preservation of the no-action assignment, then selected Windows-key mode and checked the stored assignment.
- Passed no-action activation/exit and Windows-key dry-run checks.
- Received user confirmation of basic behavior and approval to publish on 2026-10-19.
- Systematic testing of long holds, key combinations, lock transitions, sign-in, and reboot remains incomplete.

#### Earlier 0.1.0 validation history

The following was checked on a local Windows 11 25H2 x64 PC on 2026-10-19:

- MSIX build/signing, certificate trust registration, and installation succeeded.
- Verified Copilot provider registration and visibility in Windows Settings.
- Five activations all exited and preserved the foreground window; no resident app process remained.
- Verified the stored Copilot assignment after selecting Banpilot.
- Initial user feedback indicated no action. Audio was muted, so this was not treated as verification of voice behavior.
- Physical short/long presses, combinations, sign-in, and reboot tests were not complete.

### Uninstall and restore

1. In Windows Settings, change the Copilot key target to your preferred app.
2. Uninstall **Eventide's Banpilot** from Installed apps.
3. If you no longer use the test certificate, open `certlm.msc` and remove the certificate in **Trusted People → Certificates** whose thumbprint exactly matches `build.json`. First check whether any other app uses that certificate.

### License

[MIT + Commons Clause 1.0](LICENSE) — Copyright (c) 2026 Eventide (eventide-manafield).

Starting with 0.2.1, LICENSE is included at the installation ZIP's root and inside the MSIX. The standalone Setup EXE embeds that MSIX, so the full license is available in the app's installation folder after installation.

Personal use, use at work, modification, and redistribution subject to the license conditions are allowed. Paid provision of a product or service whose value derives entirely or substantially from the software's functionality is restricted by the Commons Clause definition of **Sell**. This includes merely renaming or rebranding the app for sale, and paid hosting or support that falls within that definition.

Including the app in a larger product is not prohibited in itself. For example, installing it as a convenience on a PC whose value principally comes from its hardware is consistent with the permitted use described by the clause. Not every bundle or paid support arrangement is automatically allowed; the actual Sell definition controls. Redistribution must preserve the copyright notice and the **complete MIT and Commons Clause notices**.

The project uses the published [MIT](https://opensource.org/license/mit) and [Commons Clause 1.0](https://commonsclause.com/) texts together, with no additional custom restrictions. This is not MIT alone. Because it restricts sales, it is **source-available software, not OSI-approved open source**. This section is a summary; the English LICENSE file supplies the actual terms.

**Earlier releases:** Rights already granted for v0.2.0 and code previously published under MIT remain in effect. This change does not revoke those rights retroactively or prohibit sales of the earlier MIT-licensed material.

### References

- [Microsoft Copilot hardware key providers](https://learn.microsoft.com/en-us/windows/apps/develop/windows-integration/microsoft-copilot-key-provider)
- [Create a certificate for MSIX package signing](https://learn.microsoft.com/en-us/windows/msix/package/create-certificate-package-signing)

[Back to top](#eventides-banpilot) · [한국어](#한국어)
