import Big from 'big.js';

/**
 * Performs a mathematical operation on two numbers using the provided operator.
 *
 * @param {string|number} numberOne - The first number. If null or undefined, it is treated as 0.
 * @param {string|number} numberTwo - The second number. If null or undefined, it is treated as 1 for division and multiplication, and 0 for subtraction and addition.
 * @param {string} operation - The mathematical operation to perform. Supported operations are '+', '-', 'x', and '÷'.
 *
 * @returns {string} The result of the operation as a string.
 *
 * @throws {Error} If an unknown operation is provided.
 */
export default async function operate(numberOne, numberTwo, operation) {
  const one = Big(numberOne || "0");
  const two = Big(numberTwo || (operation === "÷" || operation === 'x' ? "1": "0")); //If dividing or multiplying, then 1 maintains current value in cases of null
  const yourBackEndServiceUrl = "http://localhost:8091/calculator/"; // Replace with your actual

  // Create an http get request to a backend service to perform addition.
  // The back end service should validate the inputs and handle any necessary validations.
  // const response = await fetch(`http://your-backend-service-url/addition?numberOne=${one}&numberTwo=${two}`);
  // if (!response.ok) {
  //   throw new Error(`Failed to perform addition: ${response.statusText}`);
  // }
  // const result = await response.json();
  // return result.result;

  if (operation === "+") {
    const response = await fetch(`${yourBackEndServiceUrl}/+/${one}/${two}/`);
    if (!response.ok) {
      // Write an error message to the console for debugging purposes.
      // Do not throw an exception here. Allow continuation by calculating locally.
      console.error(`Failed to perform remote operation '${operation}': ${response.statusText}`);
      console.info(`Using local calculation for operation '${operation}'`);
      return one.plus(two).toString();
    }
    const result = await response.json();
    return result.toString();
  }
  if (operation === "-") {
    // const response = await fetch(`${yourBackEndServiceUrl}/-/${one}/${two}/`);
    return one.minus(two).toString();
  }
  if (operation === "x") {
    // const response = await fetch(`${yourBackEndServiceUrl}/*/${one}/${two}/`);
    return one.times(two).toString();
  }
  if (operation === "÷") {
    if (two === "0") {
      alert("Divide by 0 error");
      return "0";
    } else {
      // const response = await fetch(`${yourBackEndServiceUrl}/d/${one}/${two}/`);
      return one.div(two).toString();
    }
  }
  throw Error(`Unknown operation '${operation}'`);
}