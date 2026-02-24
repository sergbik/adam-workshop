def fibonacci(n):
    if n <= 0:
        return 0
    elif n == 1:
        return 1
    else:
        a, b = 0, 1
        for _ in range(2, n + 1):
            a, b = b, a + b
        return b

if __name__ == "__main__":
    import sys
    # Expecting one argument: the number N
    if len(sys.argv) < 2:
        print("Usage: python3 test_fibonacci.py <N>", file=sys.stderr)
        sys.exit(1)
    
    try:
        n = int(sys.argv[1])
        result = fibonacci(n)
        print(f"Fibonacci({n}) = {result}")
        sys.exit(0) # Indicate success
    except ValueError:
        print(f"Error: Invalid input '{sys.argv[1]}'. N must be an integer.", file=sys.stderr)
        sys.exit(1) # Indicate failure
    except Exception as e:
        print(f"An unexpected error occurred: {e}", file=sys.stderr)
        sys.exit(1) # Indicate failure
