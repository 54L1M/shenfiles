local status, bufdel = pcall(require, "bufdel")

if not status then
  return
end

bufdel.setup{
  quit = true
}
