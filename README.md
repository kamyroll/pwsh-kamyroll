> **Warning**
> 
> This is more or less deprecated, should still work, but I recommend using [Kamyroll Taurin](https://github.com/kamyroll/Kamyroll-Tauri) instead as it features an entire gui experience.

# pwsh-kamyroll
A implementation of the Kamyroll API in powershell

> **Warning**
> 
> This was put together in about 15 hours, so might be buggy at some points.
> 
> I provide no warranty or gurantee of any kind.

## How to use:
1. Download `cli.ps1`
2. Run `cli.ps1` from anywhere you want.

3. (Optional) Create `C:\Users\<yourName>\.config\powershell\user_profile.ps1` and set it's contents to
```Powershell
Function startKamy {
. "<path to cli.ps1>"
}
Set-Alias Kamyroll startKamy
```
That way each time you type "Kamyroll" into powershell it will start the cli

---

The CLI was made with menus from [PSMenu](https://github.com/Sebazzz/PSMenu)
