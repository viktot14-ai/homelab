# GPU проброс: RTX 3060 → CT112 (Ollama)

## 1. Настройка BIOS (pve-node2)

- Включить IOMMU: Intel VT-d → Enable
- Primary Display: PEG (дискретная карта)
- Disable iGPU multi-monitor (если конфликтует)

## 2. GRUB / kernel параметры

```bash
# /etc/default/grub
GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on iommu=pt initcall_blacklist=sysfb_init pcie_acs_override=downstream,multifunction nofb"

update-grub
reboot
```

## 3. Проверка IOMMU

```bash
dmesg | grep -e IOMMU -e DMAR
# Должно быть: DMAR: IOMMU enabled

lspci -nn | grep -i nvidia
# Пример: 01:00.0 VGA compatible controller [0300]: NVIDIA Corporation GA106 [GeForce RTX 3060] [10de:2503] (rev a1)
```

## 4. Загрузка драйверов NVIDIA на хосте

```bash
apt-get install -y nvidia-driver firmware-misc-nonfree
reboot

# Проверка
nvidia-smi
ls -la /dev/nvidia*
# /dev/nvidia0 /dev/nvidiactl /dev/nvidia-uvm
```

## 5. Проброс устройств в CT112

```bash
pct set 112 --dev0 /dev/nvidia0
pct set 112 --dev1 /dev/nvidiactl
pct set 112 --dev2 /dev/nvidia-uvm

# Дополнительно: проброс USB или других устройств при необходимости
pct reboot 112
```

## 6. Установка драйверов внутри CT112

```bash
pct enter 112
apt-get update
apt-get install -y nvidia-driver nvidia-container-toolkit
reboot  # контейнер
```

## 7. Установка Ollama

```bash
curl -fsSL https://ollama.com/install.sh | sh
systemctl enable ollama
systemctl start ollama

# Проверка GPU
ollama ps  # должно показать GPU
```

## 8. Переключение GPU между CT112 и VM200

Скрипт `gpu-switch` на node2 переключает GPU между Ollama (LXC) и Bazzite (VM):

```bash
# GPU → Ollama (CT112)
/usr/local/bin/gpu-switch --ct 112

# GPU → Bazzite (VM200)
/usr/local/bin/gpu-switch --vm 200
```

Скрипт останавливает один потребитель, освобождает устройства, запускает другой.

## 9. Отключение RGB подсветки RTX 3060

```bash
# Установка openrgb
apt-get install -y openrgb

# Отключить подсветку
openrgb --mode off

# Или через xinit (без X-сервера):
openrgb --server --mode off
```

## 10. Типичные проблемы

| Проблема | Решение |
|----------|---------|
| `nvidia-smi: command not found` в CT | Установить nvidia-driver внутри контейнера |
| GPU исчезла после перезагрузки | Проверить `pct config 112` — строки `dev0/dev1/dev2` |
| `CUDA error: no device` | Проверить `/dev/nvidia*` внутри CT: `ls -la /dev/nvidia*` |
| RGB подсветка горит | `openrgb --mode off` или `nvidia-smi -pm 1` |
| CT не видит GPU после gpu-switch | Перезагрузить CT: `pct reboot 112` |