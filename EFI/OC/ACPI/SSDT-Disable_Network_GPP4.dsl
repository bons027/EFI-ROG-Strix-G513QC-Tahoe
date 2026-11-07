/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20230628 (64-bit version)
 * Copyright (c) 2000 - 2023 Intel Corporation
 * 
 * Disassembling to symbolic ASL+ operators
 *
 * Disassembly of /home/hatch/workspace/hackintosh-rog/ROG-fixed/EFI/OC/ACPI/SSDT-Disable_Network_GPP4.aml, Wed Nov  4 16:54:36 2026
 *
 * Original Table Header:
 *     Signature        "SSDT"
 *     Length           0x000000D4 (212)
 *     Revision         0x02
 *     Checksum         0xCE
 *     OEM ID           "ZPSS"
 *     OEM Table ID     "DNET"
 *     OEM Revision     0x00000000 (0)
 *     Compiler ID      "INTL"
 *     Compiler Version 0x20251212 (539300370)
 */
DefinitionBlock ("", "SSDT", 2, "ZPSS", "DNET", 0x00000000)
{
    External (_SB_.PCI0.GPP4.WLAN, DeviceObj)

    Method (\_SB.PCI0.GPP4.WLAN._DSM, 4, NotSerialized)  // _DSM: Device-Specific Method
    {
        If ((!Arg2 || (_OSI ("Darwin") == Zero)))
        {
            Return (Buffer (One)
            {
                 0x03                                             // .
            })
        }

        Return (Package (0x0A)
        {
            "name", 
            Buffer (0x09)
            {
                "#network"
            }, 

            "IOName", 
            "#display", 
            "class-code", 
            Buffer (0x04)
            {
                 0xFF, 0xFF, 0xFF, 0xFF                           // ....
            }, 

            "vendor-id", 
            Buffer (0x04)
            {
                 0xFF, 0xFF, 0x00, 0x00                           // ....
            }, 

            "device-id", 
            Buffer (0x04)
            {
                 0xFF, 0xFF, 0x00, 0x00                           // ....
            }
        })
    }
}

