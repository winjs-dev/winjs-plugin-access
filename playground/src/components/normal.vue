<template>
    <div v-access="accessId">只有 Normal 可见</div>
</template>

<script setup lang="ts">
const accessId = '/normal';
</script>
