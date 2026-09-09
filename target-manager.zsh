# ==========================================
# Persistent Target Manager 
# ==========================================

TARGET_DIR="$HOME/.shell/targets"
mkdir -p "$TARGET_DIR"

# Load saved targets on shell start
_load_targets() {
    local file name value
    for file in "$TARGET_DIR"/*(N); do
        [[ -f "$file" ]] || continue
        name="${file:t}"
        value="$(<"$file")"
        [[ -n "$value" ]] && builtin export "$name=$value"
    done
}

# Set single or auto-numbered target
set-target() {
    local name value

    if [[ $# -eq 1 ]]; then
        # Default to TARGET1, TARGET2, etc. if no variable name is provided
        local i=1
        while [[ -f "$TARGET_DIR/TARGET$i" || -n "${(P)$(echo TARGET$i)}" ]]; do
            ((i++))
        done
        name="TARGET$i"
        value="$1"
    elif [[ $# -eq 2 ]]; then
        # Force name to UPPERCASE
        name="${(U)1}"
        value="$2"
    else
        echo "[-] Usage: set-target [NAME] <IP/HOST>"
        return 1
    fi

    # Validate variable name
    if [[ ! "$name" =~ ^[A-Z_][A-Z0-9_]*$ ]]; then
        echo "[-] Invalid name: $name (Use standard variable characters)"
        return 1
    fi

    # Save and export
    print -r -- "$value" > "$TARGET_DIR/$name"
    builtin export "$name=$value"
    echo "[+] Target set: $name = $value"
}

# List active targets
target() {
    local file name value output
    output=()

    for file in "$TARGET_DIR"/*(N); do
        [[ -f "$file" ]] || continue
        name="${file:t}"
        value="${(P)name}"
        [[ -z "$value" ]] && value="$(<"$file")"
        # Color-coded output: Green for name, White for value
        output+=("$(printf '\e[1;32m%-10s\e[0m = \e[1;37m%s\e[0m' "$name" "$value")")
    done

    if [[ ${#output} -gt 0 ]]; then
        echo -e "\e[1;34m[+] Active Targets:\e[0m"
        print -l ${(o)output}
    else
        echo "[-] No active targets stored."
    fi
}

# Remove one, multiple, or all targets
untarget() {
    if [[ $# -eq 0 ]]; then
        echo "[-] Usage: untarget <NAME1> [NAME2...] OR untarget all"
        return 1
    fi

    # Unset all targets at once
    if [[ "${(L)1}" == "all" ]]; then
        local file name
        for file in "$TARGET_DIR"/*(N); do
            [[ -f "$file" ]] || continue
            name="${file:t}"
            builtin unset "$name"
        done
        rm -f "$TARGET_DIR"/*(N)
        echo "[-] All targets cleared."
        return 0
    fi

    # Unset specific targets
    local arg name
    for arg in "$@"; do
        name="${(U)arg}"
        if [[ -f "$TARGET_DIR/$name" ]]; then
            rm -f "$TARGET_DIR/$name"
            builtin unset "$name"
            echo "[-] Removed target: $name"
        else
            echo "[-] No target found: $name"
        fi
    done
}

# Load targets when a new shell starts
_load_targets
