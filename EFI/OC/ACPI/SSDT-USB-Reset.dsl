/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20230628 (64-bit version)
 * Copyright (c) 2000 - 2023 Intel Corporation
 * 
 * Disassembling to symbolic ASL+ operators
 *
 * Disassembly of /home/hatch/workspace/hackintosh-rog/ROG-fixed/EFI/OC/ACPI/SSDT-USB-Reset.aml, Wed Nov  4 16:54:37 2026
 *
 * Original Table Header:
 *     Signature        "SSDT"
 *     Length           0x000000C5 (197)
 *     Revision         0x02
 *     Checksum         0xA2
 *     OEM ID           "ZPSS"
 *     OEM Table ID     "UsbReset"
 *     OEM Revision     0x00001000 (4096)
 *     Compiler ID      "INTL"
 *     Compiler Version 0x20251212 (539300370)
 */
DefinitionBlock ("", "SSDT", 2, "ZPSS", "UsbReset", 0x00001000)
{
    External (_SB_.PCI0.GP17.XHC0.RHUB, DeviceObj)
    External (_SB_.PCI0.GP17.XHC1.RHUB, DeviceObj)

    Scope (\_SB.PCI0.GP17.XHC0.RHUB)
    {
        Method (_STA, 0, NotSerialized)  // _STA: Status
        {
            If (_OSI ("Darwin"))
            {
                Return (Zero)
            }
            Else
            {
                Return (0x0F)
            }
        }
    }

    Scope (\_SB.PCI0.GP17.XHC1.RHUB)
    {
        Method (_STA, 0, NotSerialized)  // _STA: Status
        {
            If (_OSI ("Darwin"))
            {
                Return (Zero)
            }
            Else
            {
                Return (0x0F)
            }
        }
    }
}

