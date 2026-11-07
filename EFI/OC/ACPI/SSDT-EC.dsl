/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20230628 (64-bit version)
 * Copyright (c) 2000 - 2023 Intel Corporation
 * 
 * Disassembling to symbolic ASL+ operators
 *
 * Disassembly of /home/hatch/workspace/hackintosh-rog/ROG-fixed/EFI/OC/ACPI/SSDT-EC.aml, Wed Nov  4 16:54:36 2026
 *
 * Original Table Header:
 *     Signature        "SSDT"
 *     Length           0x0000007D (125)
 *     Revision         0x02
 *     Checksum         0x0A
 *     OEM ID           "ZPSS"
 *     OEM Table ID     "EC"
 *     OEM Revision     0x00001000 (4096)
 *     Compiler ID      "INTL"
 *     Compiler Version 0x20251212 (539300370)
 */
DefinitionBlock ("", "SSDT", 2, "ZPSS", "EC", 0x00001000)
{
    External (_SB_.PCI0.SBRG, DeviceObj)

    Scope (\_SB.PCI0.SBRG)
    {
        Device (EC)
        {
            Name (_HID, "ACID0001")  // _HID: Hardware ID
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (_OSI ("Darwin"))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }
        }
    }
}

