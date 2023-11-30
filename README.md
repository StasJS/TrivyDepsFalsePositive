# TrivyDepsFalsePositive

This repo exists as a minimal example to illustrate what I believe to be a false positive flag in Trivy, based upon a misunderstanding of how dependencies are managed in .NET.

In this illustration, Trivy highlights two vulnerabilities on our example image, with the following output:

```
App/TrivyDepsJsonFalsePositive.deps.json (dotnet-core)
======================================================
Total: 2 (UNKNOWN: 0, LOW: 0, MEDIUM: 0, HIGH: 2, CRITICAL: 0)

┌────────────────────────────────┬───────────────┬──────────┬────────┬───────────────────┬───────────────┬───────────────────────────────────────────────────────────┐
│            Library             │ Vulnerability │ Severity │ Status │ Installed Version │ Fixed Version │                           Title                           │
├────────────────────────────────┼───────────────┼──────────┼────────┼───────────────────┼───────────────┼───────────────────────────────────────────────────────────┤
│ System.Net.Http                │ CVE-2018-8292 │ HIGH     │ fixed  │ 4.3.0             │ 4.3.4         │ .NET Core: information disclosure due to authentication   │
│                                │               │          │        │                   │               │ information exposed in a redirect...                      │
│                                │               │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2018-8292                 │
├────────────────────────────────┼───────────────┤          │        │                   ├───────────────┼───────────────────────────────────────────────────────────┤
│ System.Text.RegularExpressions │ CVE-2019-0820 │          │        │                   │ 4.3.1         │ dotnet: timeouts for regular expressions are not enforced │
│                                │               │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2019-0820                 │
└────────────────────────────────┴───────────────┴──────────┴────────┴───────────────────┴───────────────┴───────────────────────────────────────────────────────────┘
```

In order to reproduce this output, run `RunTrivy.sh`.

I've simulated this scenario by referencing a single dependency - `xunit v2.6.2`. This library tries to be as permissive as possible, so sets a minimum .NET Standard version of 1.6.
`System.Net.Http` and `System.Text.RegularExpressions` enter the fold via this transitive dependency. 
I've used this example because if you look over at the xunit project, it's [flooded with people raising issues for these exact violations](https://github.com/search?q=repo%3Axunit%2Fxunit+4.3.0+&type=issues) (and that's how I became aware of this problem).
But I'm sure similar things are happening for other library maintainers that set low minimum .NET Standard versions.

In `/bin/Release/net6.0/publish`, the *.deps.json file does indeed feature references to `System.Net.Http v4.3.0` and `System.Text.RegularExpressions v4.3.0`. But this does not mean these are the versions that will be used at runtime.
Indeed neither dll exist under `/bin/Release/net6.0/publish`, nor under `/App` within the `core-counter` container.

In fact, on the container, the only reference to them is under `/usr/share/dotnet/shared/Microsoft.NETCore.App/6.0.25/` - try `find / | grep "System.Net.Http.dll"` - i.e. using the version that comes with the runtime.

It's not sufficient to do a simple scan of the *.deps.json folder looking for vulnerable packages. What's there needs to be interpreted within the framing of the runtime that's targeted.

If we run `dotnet add package System.Net.Http -v 4.3.4`, we can appease Trivy by 'pinning' to a 'secure' version...
- `v4.3.0` would _still_ appear in the *.deps.json file. However the entry under `"NETStandard.Library/1.6.1"` changes to `v4.3.4` - I suspect this is the difference Trivy cares about.
- Re-running `RunTrivy.sh`, we still see no `System.Net.Http.dll` in the output folder.

Except now we've taken this incredibly confusing artificial dependency.
