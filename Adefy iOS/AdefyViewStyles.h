/*
Helper methods to style app elements in a consistent manner.
 */

// Gives us classic bordered buttons, similar to our website.
static void styleButton(UIButton *button) {
  button.layer.borderWidth = 2.0f;
  button.layer.borderColor = [[UIColor whiteColor] CGColor];
  button.layer.cornerRadius = 8.0f;
}