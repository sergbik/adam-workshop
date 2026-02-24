import os
import sys
from workshop_manager import WorkshopManager

# Define paths
workshop_path = "/Users/eva/.openclaw/workspace/adam-workshop"
eva_bios_path = "/Volumes/Биос Ева/" # This path might not be used directly by manager.py but kept for consistency

# Argument for the fibonacci test
n_value = 10 
if len(sys.argv) > 1:
    try:
        n_value = int(sys.argv[1])
    except ValueError:
        print(f"Invalid N value '{sys.argv[1]}'. Using default N=10.", file=sys.stderr)

# Instantiate the WorkshopManager
manager = WorkshopManager(workshop_path, eva_bios_path)

# Define the test script path
test_script_path = os.path.join(workshop_path, "test_fibonacci.py")

# Run the self-correction cycle
print(f"--- Running Fibonacci test for N={n_value} ---")
analysis_result = manager.run_self_correction_cycle(test_script_path, str(n_value))

# Output the analysis
print("\n--- Test Analysis ---")
print(f"Success: {analysis_result['success']}")
print(f"Message: {analysis_result['message']}")
if analysis_result['corrections']:
    print("Suggested Corrections:")
    for corr in analysis_result['corrections']:
        print(f"  - {corr}")
