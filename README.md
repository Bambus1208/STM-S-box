# STM S-box
This repository contains implementations from my bachelor thesis titled "A Proper Evaluation of Self-Timed Masking." The main goal of this thesis is to thoroughly investigate the security provided by Self-Timed Masking (STM)[SBB+22] techniques. Self-Timed Masking is an advanced cryptographic technique designed to improve the resistance of cryptographic operations to side-channel attacks, in particular to power analysis attacks such as Differential Power Analysis (DPA).

In this repository you will find several implementations that demonstrate the use of STM in cryptographic S-boxes. These implementations are tested and evaluated using side-channel analysis (SCA) techniques to measure their effectiveness against these attacks. 

## Usage 

### Prerequisites
- **Windows**: The steps below are for Windows users.
- Install [Icarus Verilog](https://github.com/steveicarus/iverilog), a compiler for Verilog HDL.
- Install [GTKWave](https://github.com/gtkwave/gtkwave), a fully featured GTK+ based wave viewer.

### Installation
1. **Download and install [Icarus Verilog](https://github.com/steveicarus/iverilog)**:
   - Follow the installation instructions on the GitHub page or the official website.
2. **Download and install [GTKWave](https://github.com/gtkwave/gtkwave)**:
   - Follow the installation instructions on the GitHub page or the official website.

### Running the Implementation
1. **Clone the repository**:
    ```sh
    git clone https://github.com/Bambus1208/STM-S-box.git
    cd stm-s-box
    ```
2. **Compile and run the Verilog file**:
    ```sh
    .\iver.bat .\file.v
    ```

### File Structure
- `iver.bat`: Batch script to compile and run Verilog files using Icarus Verilog.
- `dom_sbox_unsecure.v`: Verilog file containing the implementation of a DOM S-Box, which is insecure due to the lack of register barriers.
- `dpl_dom_sbox_pipelined.v`: Verilog file containing the implementation of a DOM S-Box in DPL.
- `dpl_stm_sbox.v`: Verilog file containing the implementation of a Self-Timed Masked S-Box in DPL, which works for simulation but not for FPGA (SAKURA-G (Spartan 6)) usage.
- `dpl_stm_hw_weak_latches_sbox.v`: Verilog file containing the implementation of a Self-Timed Masked S-Box in DPL with weakly indicating latches, which works for FPGA usage.
- `dpl_stm_hw_strong_latches_sbox.v`: Verilog file containing the implementation of a Self-Timed Masked S-Box in DPL with strongly indicating latches, which works for FPGA usage.

## Related Works

### aes-dom [GMK16]
[DOM](https://github.com/hgrosz/aes-dom) Protected Hardware Implementation of AES by Hannes Gross. The paper is [GMK16](https://eprint.iacr.org/2016/486.pdf).

### PRNG
[Trivium](https://github.com/uclcrypto/randomness_for_hardware_masking/blob/main/Unrolled%20Stream%20Ciphers/Trivium.vhd) as a PRNG by Thorben Moos.

### Self-Timed Masking [SBB+22]
This work is based on the paper [Self-Timed Masking](https://eprint.iacr.org/2022/641.pdf) by Mateus Simões, Lilian Bossuet, Nicolas Bruneau, Vincent Grosso, Patrick Haddad, and Thomas Sarno.

## Contributing
We welcome contributions! Please follow these steps:
1. Fork the repository.
2. Create a new branch (`git checkout -b feature-branch`).
3. Commit your changes (`git commit -am 'Add new feature'`).
4. Push to the branch (`git push origin feature-branch`).
5. Open a pull request.
