-- Enable realtime for chat_rooms table so clients can be notified when chat rooms are created
ALTER PUBLICATION supabase_realtime ADD TABLE chat_rooms;

-- Also enable realtime for matches table to sync status changes
ALTER PUBLICATION supabase_realtime ADD TABLE matches;
