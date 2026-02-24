import os
import subprocess
import json
import logging

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

class WorkshopManager:
    def __init__(self, workshop_path, eva_bios_path):
        self.workshop_path = workshop_path
        self.eva_bios_path = eva_bios_path
        logging.info(f"WorkshopManager initialized for workshop: {self.workshop_path}, Eva BIOS: {self.eva_bios_path}")

    def run_test(self, test_script_path, *args):
        """
        Executes a given test script and captures its output.
        Returns (stdout, stderr, returncode).
        """
        command = ['python3', test_script_path] + list(args)
        logging.info(f"Running test: {' '.join(command)}")
        try:
            result = subprocess.run(
                command,
                capture_output=True,
                text=True,
                check=False  # Don't raise exception for non-zero exit codes
            )
            logging.info(f"Test finished with return code: {result.returncode}")
            return result.stdout, result.stderr, result.returncode
        except Exception as e:
            logging.error(f"Error running test script {test_script_path}: {e}")
            return "", str(e), 1

    def analyze_test_results(self, stdout, stderr, returncode):
        """
        Analyzes test results to determine success/failure and suggest corrections.
        Returns a dictionary with analysis and suggested self-correction actions.
        """
        analysis = {"success": False, "message": "Test failed.", "corrections": []}
        
        if returncode == 0:
            analysis["success"] = True
            analysis["message"] = "Test passed successfully."
            logging.info("Test passed.")
        else:
            analysis["message"] = f"Test failed with code {returncode}. Stderr: {stderr}"
            logging.warning("Test failed. Analyzing for corrections.")
            # Simple example of self-correction suggestion
            if "ModuleNotFoundError" in stderr:
                analysis["corrections"].append("Check if all required Python packages are installed (e.g., pip install <package>).")
            elif "SyntaxError" in stderr:
                analysis["corrections"].append("Review Python syntax in the test script.")
            # More advanced analysis would go here

        return analysis

    def apply_self_correction(self, analysis):
        """
        Applies suggested self-corrections (placeholder for now).
        """
        if analysis["corrections"]:
            logging.info("Applying self-corrections (placeholder).")
            # In a real scenario, this would involve modifying code,
            # rerunning tests, or generating new code.
        else:
            logging.info("No specific self-corrections suggested.")

    def run_self_correction_cycle(self, test_script_path, *args):
        """
        Executes a full self-correction cycle: run test, analyze, apply correction.
        """
        logging.info("Starting self-correction cycle.")
        stdout, stderr, returncode = self.run_test(test_script_path, *args)
        analysis = self.analyze_test_results(stdout, stderr, returncode)
        
        if analysis["success"]:
            logging.info("Self-correction cycle complete. Test passed.")
        else:
            logging.warning("Self-correction cycle attempted. Test failed. Details:")
            logging.warning(json.dumps(analysis, indent=2))
            self.apply_self_correction(analysis) # Placeholder

        return analysis

if __name__ == "__main__":
    # Example Usage (this part won't run in OpenClaw directly via simple exec)
    # You would typically instantiate and call methods from another script or task.
    
    # Dummy paths for direct testing
    dummy_workshop = "/tmp/adam_workshop_dummy"
    dummy_eva_bios = "/tmp/eva_bios_dummy"
    
    # Create dummy files for demonstration
    os.makedirs(dummy_workshop, exist_ok=True)
    os.makedirs(dummy_eva_bios, exist_ok=True)

    with open(os.path.join(dummy_workshop, "test_script.py"), "w") as f:
        f.write("import sys\nprint('Hello from test!')\nsys.exit(0)")

    with open(os.path.join(dummy_workshop, "failing_test_script.py"), "w") as f:
        f.write("import non_existent_module\nprint('This will fail!')")

    manager = WorkshopManager(dummy_workshop, dummy_eva_bios)
    
    print("\n--- Running successful test cycle ---")
    manager.run_self_correction_cycle(os.path.join(dummy_workshop, "test_script.py"))

    print("\n--- Running failing test cycle ---")
    manager.run_self_correction_cycle(os.path.join(dummy_workshop, "failing_test_script.py"))
