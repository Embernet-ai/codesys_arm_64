# CODESYS Runtime ARM

**Containerized Industrial PLC - Because your factory deserves cloud-native too** 🏭

Transform your k3s cluster into an industrial-grade PLC controller with CODESYS Control for Linux ARM SL. Single-pod deployment with integrated WebVisu, supporting both 32-bit and 64-bit ARM architectures.

## What You Get

🤖 **Single PLC Runtime Pod with:**
- IEC 61131-3 compliant SoftPLC
- **Integrated WebVisu** web server (built-in HMI)
- Fieldbus support (EtherCAT, PROFINET, Modbus, etc.)
- OPC UA server for Industry 4.0
- Real-time capable (with RT kernel)
- **Architecture support:** ARM 32-bit (ARMv7) AND ARM 64-bit (ARMv8)

## Quick Deploy

Deploy via Rancher UI - browse to **Apps & Marketplace**, find "CODESYS Runtime", click install, configure via wizard, profit. 

Or via command line if you're into that:

```bash
helm install my-plc fireball-podstore/codesys-runtime-arm \
  --namespace codesys-plc \
  --create-namespace
```

Boom. You've got a PLC running in Kubernetes. What a time to be alive.

## Important Stuff

⚠️ **Runs in Demo Mode** by default (2-hour runtime limit, manual restart required)  
⚠️ **Requires Privileged Mode** for I/O access (yes, we know)  
⚠️ **Officially Unsupported** by CODESYS for containers (we're rebels)  

For production: get a real license, harden security, test extensively.

## Features

- **32-bit & 64-bit Support**: ARMv7 (Raspberry Pi 2/3) or ARMv8 (Raspberry Pi 4+)
- **Integrated WebVisu**: Built-in web server for HMI (no separate pod needed)
- **Persistent Storage**: Your PLC programs survive pod restarts
- **Resource Presets**: Small/Medium/Large (because YAML math is hard)
- **Rancher Optimized**: Pretty UI wizard included
- **OPC UA Built-in**: Industry 4.0 ready out of the box
- **Fieldbus Ready**: EtherCAT, PROFINET, Modbus - all the acronyms

## Connect & Program

1. Get the runtime IP: `kubectl get svc -n codesys-plc`
2. Open CODESYS Development System
3. Connect to `<RUNTIME_IP>:1217`
4. Download your ladder logic masterpiece
5. Access WebVisu at `http://<RUNTIME_IP>:8080` (same pod, different port)

## Demo Mode Restart

Demo mode expires after 2 hours (thanks, licensing). Restart it:

```bash
kubectl rollout restart deployment -n codesys-plc -l app.kubernetes.io/component=plc-runtime
```

Set a cron job if you're lazy. We won't judge.

## Security Notes

This thing runs privileged because industrial I/O doesn't care about your container security policies. For production:

- Use dedicated nodes
- Enable network policies
- Turn on WebVisu auth
- Read your insurance policy carefully

## Ports You Need to Know

- **1217**: CODESYS communication (programming & debugging)
- **4840**: OPC UA server (Industry 4.0 integration)
- **8080**: WebVisu HTTP (integrated web HMI)

All served from the same pod. One runtime, three protocols. Efficiency.

## Resources

Default medium preset gets you 500m-1000m CPU and 512Mi-1Gi RAM. Scale up if your PLC application is doing something impressive. Or if you just like watching kubectl top.

## Troubleshooting

**"It won't start"** → Check if privileged mode is allowed  
**"Can't connect"** → Verify service has external IP  
**"WebVisu is blank"** → Runtime probably crashed, check logs  
**"Demo expired"** → kubectl rollout restart, friend

## Why This Exists

Because sometimes you need a PLC but don't want to rack-mount a beige box from 2003. Also, YAML is apparently the new ladder logic. Who knew?

## License

You'll need a CODESYS license for production. Demo mode is fine for tinkering, testing, and impressing your boss at demo day.

---

**Fireball Industries Podstore** - Patrick Ryan  
*Making industrial automation less industrial since 2026*

Got questions? Open an issue. Got complaints? Those too. Got a better way? PRs welcome.
