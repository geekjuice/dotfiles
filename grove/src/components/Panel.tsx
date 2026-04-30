import React from "react";
import { Box, Text } from "ink";

type Props = {
  title: string;
  width?: number | string;
  height?: number | string;
  focused?: boolean;
  badge?: string;
  badgeColor?: string;
  children: React.ReactNode;
}

export function Panel({
  title,
  width,
  height,
  focused = false,
  badge,
  badgeColor,
  children,
}: Props) {
  const borderColor = focused ? "green" : "gray";

  return (
    <Box
      flexDirection="column"
      width={width}
      height={height}
      borderStyle="round"
      borderColor={borderColor}
    >
      <Box>
        <Text bold color={focused ? "green" : "white"}>
          {title}
        </Text>
        {badge && (
          <Text color={badgeColor || "cyan"}> [{badge}]</Text>
        )}
      </Box>
      <Box flexDirection="column" flexGrow={1}>
        {children}
      </Box>
    </Box>
  );
}
